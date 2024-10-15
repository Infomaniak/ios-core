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

/// Something that behaves like a collection and can also be sequenced
///
/// Some of the conforming types are Array, ArraySlice, Dictionary …
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias SequenceableCollection = Collection & Sequence

/// A concurrent way to map some computation with a closure to a collection of generic items.
///
/// Use default settings for optimised queue depth
///
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
@available(*, deprecated, message: "Use <Collection>.concurrentMap from the InfomaniakConcurrency package instead")
public struct ParallelTaskMapper {
    /// private processing TaskQueue
    private let taskQueue: TaskQueue

    /// Init function
    /// - Parameter concurrency: execution depth, keep default for optimized threading.
    public init(concurrency: Int = max(4, ProcessInfo.processInfo.activeProcessorCount) /* parallel by default */ ) {
        assert(concurrency > 0, "zero concurrency locks execution")
        taskQueue = TaskQueue(concurrency: concurrency)
    }

    /// Map a task to a collection of items
    ///
    /// With this, you can easily _parallelize_  *async/await* code.
    ///
    /// This is using an underlying `TaskQueue` (with an optimized queue depth)
    /// Using it to apply work to each item of a given collection.
    /// - Parameters:
    ///   - collection: The input collection of items to be processed. Supports Array / ArraySlice / Dictionary …
    ///   - toOperation: The operation to be applied to the `collection` of items
    /// - Returns: An ordered processed collection of the desired type
    public func map<Input, Output>(
        collection: some SequenceableCollection<Input>,
        toOperation operation: @escaping @Sendable (_ item: Input) async throws -> Output?
    ) async throws -> [Output?] {
        // Using an ArrayAccumulator to preserve the order of results
        let accumulator = ArrayAccumulator(count: collection.count, wrapping: Output.self)

        // Using a TaskGroup to track completion
        _ = try await withThrowingTaskGroup(of: Void.self, returning: Void.self) { taskGroup in
            for (index, item) in collection.enumerated() {
                taskGroup.addTask {
                    let result = try await self.taskQueue.enqueue {
                        try await operation(item)
                    }

                    try? await accumulator.set(item: result, atIndex: index)
                }
            }

            // await completion of all tasks
            try await taskGroup.waitForAll()
        }

        // Get the accumulated results
        let accumulated = await accumulator.accumulation
        return accumulated
    }
}
