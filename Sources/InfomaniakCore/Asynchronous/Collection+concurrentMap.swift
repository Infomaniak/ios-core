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

/// Top level `Collection` extension is arguably more swifty, has a more native look and feel.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public extension Collection {
    /// Maps a task to a collection of items concurrently. Input order __preserved__.
    ///
    /// With this, you can easily __parallelize__  _async/await_ code.
    ///
    /// This is using an underlying `TaskQueue`, with an optimized queue depth.
    ///
    /// - Parameters:
    ///   - transform: The operation to be applied to the `Collection` of items
    /// - Returns: An ordered processed collection of the desired type.
    func concurrentMap<Input, Output>(
        transform: @escaping @Sendable (_ item: Input) async throws -> Output
    ) async rethrows -> [Output] where Element == Input {
        // Concurrency making use of all the cores available
        let optimalConcurrency = Swift.max(4, ProcessInfo.processInfo.activeProcessorCount)

        // Dispatch work on a TaskQueue for concurrency.
        let taskQueue = TaskQueue(concurrency: optimalConcurrency)

        // Using an ArrayAccumulator to preserve original collection order.
        let accumulator = ArrayAccumulator(count: count, wrapping: Output.self)

        // Using a TaskGroup to track completion only.
        _ = try await withThrowingTaskGroup(of: Void.self, returning: Void.self) { taskGroup in
            for (index, item) in self.enumerated() {
                taskGroup.addTask {
                    let result = try await taskQueue.enqueue {
                        try await transform(item)
                    }

                    try await accumulator.set(item: result, atIndex: index)
                }
            }

            // await completion of all tasks.
            try await taskGroup.waitForAll()
        }

        // Get the accumulated results.
        let accumulated = await accumulator.compactAccumulation

        // Sanity check, should never append
        guard accumulated.count == count else {
            fatalError("Internal consistency error. Got:\(accumulated.count) Expecting:\(count)")
        }

        return accumulated
    }

    /// Maps a task with nullable result __concurrently__, returning only non nil values. Input order __preserved__.
    ///
    /// With this, you can easily __parallelize__  _async/await_ code.
    ///
    /// This is using an underlying `TaskQueue`, with an optimized queue depth.
    ///
    /// - Parameters:
    ///   - transform: The operation to be applied to the `Collection` of items
    /// - Returns: An ordered processed collection of the desired type, containing non nil values.
    func concurrentCompactMap<Input, Output>(
        transform: @escaping @Sendable (_ item: Input) async throws -> Output?
    ) async rethrows -> [Output] where Element == Input {
        // Concurrency making use of all the cores available
        let optimalConcurrency = Swift.max(4, ProcessInfo.processInfo.activeProcessorCount)

        // Dispatch work on a TaskQueue for concurrency.
        let taskQueue = TaskQueue(concurrency: optimalConcurrency)

        // Using an ArrayAccumulator to preserve original collection order.
        let accumulator = ArrayAccumulator(count: count, wrapping: Output.self)

        // Using a TaskGroup to track completion only.
        _ = try await withThrowingTaskGroup(of: Void.self, returning: Void.self) { taskGroup in
            for (index, item) in self.enumerated() {
                taskGroup.addTask {
                    let result = try await taskQueue.enqueue {
                        try await transform(item)
                    }

                    try await accumulator.set(item: result, atIndex: index)
                }
            }

            // await completion of all tasks.
            try await taskGroup.waitForAll()
        }

        // Get the accumulated results.
        let accumulated = await accumulator.compactAccumulation
        return accumulated
    }
}
