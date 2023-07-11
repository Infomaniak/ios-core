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
public typealias CurriedClosure<Input, Output> = (Input) -> Output

/// A closure that take no argument and return nothing, but technically curried.
///
/// Calling this closure type requires the use of `Void` which is, in swift, an empty tuple `()`.
public typealias SimpleClosure = CurriedClosure<Void, Void>

/// Append a SimpleClosure to another one
///
/// This allows you to append / prepend a closure to another one with the + operator.
/// This is not function composition.
public func + (_ lhs: @escaping SimpleClosure, _ rhs: @escaping SimpleClosure) -> SimpleClosure {
    let closure: SimpleClosure = { _ in
        lhs(())
        rhs(())
    }
    return closure
}
