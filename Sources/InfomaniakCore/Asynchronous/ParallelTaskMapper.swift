/*
 Infomaniak Core - iOS
 Copyright (C) 2021 Infomaniak Network SA

 This program is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.

 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.

 You should have received a copy of the GNU General Public License
 along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

import Foundation

/// Something that can cancel all child processes
public protocol CancelAllable {
    /// cancel all child processes
    func cancelAll()
}

public protocol Completionable {
    mutating func waitForAll() async throws
}

public protocol TaskGroupAble: CancelAllable & Completionable {
    
}

extension ThrowingTaskGroup: TaskGroupAble {}

/// A concurrent way to map some computation with a closure to a collection of generic items.
///
/// Use default settings for optimised queue depth
///
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public struct ParallelTaskMapper {
    
    
    /// Something that can return the result asynchronously or cancel existing work
    public struct ResultHandler<T>: TaskGroupAble {
        init(accumulator: ArrayAccumulator<T>, taskGroup: TaskGroupAble?, wrapping: T.Type) {
            self.accumulator = accumulator
            self.taskGroup = taskGroup
        }

        private var accumulator: ArrayAccumulator<T>
        private var taskGroup: TaskGroupAble?

        /// Wait for completion of tasks and return the result
        public var accumulation: [T?] {
            mutating get async throws {
                try await self.taskGroup?.waitForAll()
                return await accumulator.accumulation
            }
        }
        
        public mutating func waitForAll() async throws {
            try await self.taskGroup?.waitForAll()
        }
        
        public func cancelAll() {
            self.taskGroup?.cancelAll()
        }
        
    }

    /// internal processing TaskQueue
    let taskQueue: TaskQueue

    /// Init function
    /// - Parameter concurrency: execution depth, keep default for optimized threading.
    public init(concurrency: Int = max(4, ProcessInfo.processInfo.activeProcessorCount) /* parallel by default */ ) {
        assert(concurrency > 0, "zero concurrency locks execution")
        print("concurrency = \(concurrency)")
        taskQueue = TaskQueue(concurrency: concurrency)
    }

    /// Map a task to a collection of items
    ///
    /// With this, you can easily _parallelize_  *async/await* code.
    ///
    /// This is using an underlying `TaskQueue` (with an optimized queue depth)
    /// Using it to apply work to each item of a given collection.
    /// - Parameters:
    ///   - collection: The input collection of items to be processed
    ///   - toOperation: The operation to be applied to the `collection` of items
    /// - Returns: A result handler that can cancel running tasks
    public func map<T, U>(collection: [U],
                          toOperation operation: @escaping @Sendable (_ item: U) async throws -> T?) async throws
        -> ResultHandler<T> {
        // Using an ArrayAccumulator to preserve the order of results
        let accumulator = ArrayAccumulator(count: collection.count, wrapping: T.self)

        // Using a TaskGroup to track completion
        var taskGroupable: TaskGroupAble?
        let _ = try await withThrowingTaskGroup(of: Void.self, returning: Void.self) { taskGroup in
            taskGroupable = taskGroup
            for (index, item) in collection.enumerated() {
                taskGroup.addTask {
                    guard !Task.isCancelled else { return }

                    let result = try await self.taskQueue.enqueue {
                        try await operation(item)
                    }

                    try? await accumulator.set(item: result, atIndex: index)
                }
            }
        }

        let resultHandler = ResultHandler(accumulator: accumulator,
                                          taskGroup: taskGroupable,
                                          wrapping: T.self)
        return resultHandler
    }
}
