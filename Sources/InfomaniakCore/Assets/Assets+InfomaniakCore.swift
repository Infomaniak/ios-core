//
//  Assets+InfomaniakCore.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 23.12.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

// swiftlint:disable all
#if os(macOS)
    import AppKit
#elseif os(iOS)
    import UIKit
#elseif os(tvOS) || os(watchOS)
    import UIKit
#endif
// swiftlint:disable superfluous_disable_command file_length implicit_return

// MARK: - Asset Catalogs

// swiftlint:disable identifier_name line_length nesting type_body_length type_name
public enum InfomaniakCoreAsset {
    public static let backgroundCardView = InfomaniakCoreColor(name: "backgroundCardView")
    public static let backgroundCardViewSelected = InfomaniakCoreColor(name: "backgroundCardViewSelected")

}
// swiftlint:enable identifier_name line_length nesting type_body_length type_name

// MARK: - Implementation Details
public struct InfomaniakCoreColor {
    public fileprivate(set) var name: String

    public var color: UIColor {
        return UIColor(named: name, in: Bundle.module, compatibleWith: nil)!
    }

}
