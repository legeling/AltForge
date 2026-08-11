//
//  UIColor+AltStore.swift
//  AltStore
//
//  Created by Riley Testut on 5/9/19.
//  Copyright © 2019 Riley Testut. All rights reserved.
//

import UIKit

public extension UIColor
{
    private static let colorBundle = Bundle(for: DatabaseManager.self)

    static var altPrimary: UIColor {
        return UserDefaults.standard.preferredTheme.primaryColor
    }

    static var altSourceTint: UIColor {
        return UserDefaults.standard.preferredTheme.sourceTintColor
    }
    static let deltaPrimary = UIColor(named: "DeltaPrimary", in: colorBundle, compatibleWith: nil)
    static let clipPrimary = UIColor(named: "ClipPrimary", in: colorBundle, compatibleWith: nil)
    
    static let refreshRed = UIColor(named: "RefreshRed", in: colorBundle, compatibleWith: nil)!
    static let refreshOrange = UIColor(named: "RefreshOrange", in: colorBundle, compatibleWith: nil)!
    static let refreshYellow = UIColor(named: "RefreshYellow", in: colorBundle, compatibleWith: nil)!
    static let refreshGreen = UIColor(named: "RefreshGreen", in: colorBundle, compatibleWith: nil)!
}

public extension AltTheme
{
    var primaryColor: UIColor {
        switch self
        {
        case .forgeRed:
            return UIColor(lightHex: 0xB51843, darkHex: 0xF04A6D)
        case .oceanBlue:
            return UIColor(lightHex: 0x075EB8, darkHex: 0x4C9BEE)
        case .indigo:
            return UIColor(lightHex: 0x5143A5, darkHex: 0x8B7BE5)
        case .rose:
            return UIColor(lightHex: 0x8F286B, darkHex: 0xD263AC)
        }
    }

    var sourceTintColor: UIColor {
        switch self
        {
        case .forgeRed:
            return UIColor(lightHex: 0x8E1735, darkHex: 0x6A2035)
        case .oceanBlue:
            return UIColor(lightHex: 0x124E86, darkHex: 0x173E63)
        case .indigo:
            return UIColor(lightHex: 0x443A82, darkHex: 0x342E5E)
        case .rose:
            return UIColor(lightHex: 0x702554, darkHex: 0x54213F)
        }
    }
}

public extension Notification.Name
{
    static let altThemeDidChange = Notification.Name("com.legeling.AltForge.ThemeDidChange")
}

private extension UIColor
{
    convenience init(lightHex: UInt32, darkHex: UInt32)
    {
        self.init { traits in
            let hex = traits.userInterfaceStyle == .dark ? darkHex : lightHex
            return UIColor(red: CGFloat((hex >> 16) & 0xff) / 255.0,
                           green: CGFloat((hex >> 8) & 0xff) / 255.0,
                           blue: CGFloat(hex & 0xff) / 255.0,
                           alpha: 1.0)
        }
    }
}
