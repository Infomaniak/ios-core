//
//  UserProfile.swift
//  InfomaniakCore
//
//  Created by Philippe Weidmann on 23.06.20.
//  Copyright © 2020 Infomaniak. All rights reserved.
//

import UIKit
import Kingfisher

public protocol InfomaniakUser {
    var id: Int { get }
    var email: String { get }
    var displayName: String { get }
    var avatar: String { get }

    func getAvatar(size: CGSize, completion: @escaping (UIImage) -> Void)
}
public extension InfomaniakUser {
    func getAvatar(size: CGSize = CGSize(width: 40, height: 40), completion: @escaping (UIImage) -> Void) {
        if let url = URL(string: avatar) {
            KingfisherManager.shared.retrieveImage(with: url) { (result) in
                if let avatarImage = try? result.get().image {
                    completion(avatarImage)
                }
            }
        } else {
            let backgroundColor = UIColor.backgroundColor(from: id)
            completion(UIImage.getInitialsPlaceholder(with: displayName, size: size, backgroundColor: backgroundColor))
        }
    }
}

public class UserProfile: Codable, InfomaniakUser {

    public let id: Int
    public let userId: Int
    public let login: String
    public let email: String
    public let firstname: String
    public let lastname: String
    public let displayName: String
    public let dateLastChangedPassword: Int?
    public let otp: Bool
    public let sms: Bool
    public let smsPhone: String?
    public let yubikey: Bool
    public let infomaniakApplication: Bool
    public let doubleAuth: Bool
    public let remainingRescueCode: Int
    public let securityAssistant: Int
    public let securityCheck: Bool
    public let emailValidate: String?
    public let emailReminderValidate: String?
    public let validatedAt: Date?
    public let lastLoginAt: Date?
    public let administrationLastlogin: Date?
    private let _avatar: String?
    public let phones: [Phone]?
    public let phoneReminderValidate: String?
    public let emails: [Email]?
    public var backupEmail: Email? {
        return emails?.first(where: { (email) -> Bool in
            return email.reminder
        })
    }
    public var phoneNumber: Phone? {
        get {
            return phones?.first(where: { (phone) -> Bool in
                return phone.reminder
            })
        }
    }
    public var isEmailValid: Bool {
        return email == emailValidate && emailValidate != nil
    }
    public var isBackupEmailValid: Bool {
        return backupEmail?.email == emailReminderValidate && emailReminderValidate != nil
    }
    public var isPhoneValid: Bool {
        return phoneNumber?.phone == phoneReminderValidate && phoneReminderValidate != nil
    }
    public var securityLevel: Int {
        var level = 0
        if isEmailValid {
            level += 1
        }
        if isBackupEmailValid {
            level += 1
        }
        if isPhoneValid {
            level += 1
        }
        if doubleAuth {
            level += 1
        }
        return level
    }
    public var avatar: String {
        get { return _avatar ?? "" }
        set { }
    }

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case login
        case email
        case firstname
        case lastname
        case displayName = "display_name"
        case dateLastChangedPassword = "date_last_change_password"
        case otp
        case sms
        case smsPhone = "sms_phone"
        case yubikey
        case infomaniakApplication = "infomaniak_application"
        case doubleAuth = "double_auth"
        case remainingRescueCode = "remaining_rescue_code"
        case securityAssistant = "security_assistant"
        case securityCheck = "security_check"
        case emailValidate = "email_validate"
        case emailReminderValidate = "email_reminder_validate"
        case phoneReminderValidate = "phone_reminder_validate"
        case validatedAt = "validated_at"
        case lastLoginAt = "last_login_at"
        case administrationLastlogin = "administration_last_login_at"
        case _avatar = "avatar"
        case phones
        case emails
    }
}


public class Phone: Codable {
    public let id: Int
    public let phone: String
    public let reminder: Bool
    public let checked: Bool
}


public class Email: Codable {
    public let id: Int
    public let email: String
    public let reminder: Bool
    public let contact: Bool
}
