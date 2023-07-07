/*
 Infomaniak kDrive - iOS App
 Copyright (C) 2023 Infomaniak Network SA

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

/// Represents `any` (ie. all of them not the type) curried closure, of arbitrary type.
///
/// Supports concurrency and error
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias AsyncCurriedClosure<Input, Output> = (Input) async throws -> Output

/// Execute the closure without waiting, discarding result
postfix operator ~

@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public postfix func ~ (x: @escaping AsyncCurriedClosure<Void, Any>) {
    Task {
        try? await x(())
    }
}

/// A closure that take no argument and return nothing, but technically curried.
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public typealias AsyncClosure = AsyncCurriedClosure<Void, Void>

/// Append an AsyncClosure to another one
@available(macOS 10.15, iOS 13.0, tvOS 13.0, watchOS 6.0, *)
public func + (_ lhs: @escaping AsyncClosure, _ rhs: @escaping AsyncClosure) -> AsyncClosure {
    let closure: AsyncClosure = { _ in
        try await lhs(())
        try await rhs(())
    }
    return closure
}
