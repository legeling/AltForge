//
//  UIColor+AltStore.swift
//  AltStore
//
//  Created by Riley Testut on 5/23/23.
//  Copyright © 2023 Riley Testut. All rights reserved.
//

import UIKit

extension UIColor
{
    static let altBackground = UIColor(named: "Background")!
}

extension UIColor
{
    private static let brightnessMaxThreshold = 0.85
    private static let brightnessMinThreshold = 0.35
    
    private static let saturationBrightnessThreshold = 0.5
    
    var adjustedForDisplay: UIColor {
        guard self.isTooBright || self.isTooDark else { return self }
        
        return UIColor { traits in
            var hue: CGFloat = 0
            var saturation: CGFloat = 0
            var brightness: CGFloat = 0
            guard self.getHue(&hue, saturation: &saturation, brightness: &brightness, alpha: nil) else { return self }
            
            brightness = min(brightness, UIColor.brightnessMaxThreshold)
            
            if traits.userInterfaceStyle == .dark
            {
                // Only raise brightness when in dark mode.
                brightness = max(brightness, UIColor.brightnessMinThreshold)
            }
            
            let color = UIColor(hue: hue, saturation: saturation, brightness: brightness, alpha: 1.0)
            return color
        }
    }

    var contrastingForegroundColor: UIColor {
        return UIColor { traits in
            let resolvedColor = self.resolvedColor(with: traits)
            var red: CGFloat = 0
            var green: CGFloat = 0
            var blue: CGFloat = 0
            guard resolvedColor.getRed(&red, green: &green, blue: &blue, alpha: nil) else { return .white }

            func linearComponent(_ component: CGFloat) -> CGFloat
            {
                return component <= 0.04045 ? component / 12.92 : pow((component + 0.055) / 1.055, 2.4)
            }

            let luminance = 0.2126 * linearComponent(red) + 0.7152 * linearComponent(green) + 0.0722 * linearComponent(blue)
            return luminance > 0.179 ? .black : .white
        }
    }
    
    var isTooBright: Bool {
        var saturation: CGFloat = 0
        var brightness: CGFloat = 0
        
        guard self.getHue(nil, saturation: &saturation, brightness: &brightness, alpha: nil) else { return false }
        
        let isTooBright = (brightness >= UIColor.brightnessMaxThreshold && saturation <= UIColor.saturationBrightnessThreshold)
        return isTooBright
    }
    
    var isTooDark: Bool {
        var brightness: CGFloat = 0
        guard self.getHue(nil, saturation: nil, brightness: &brightness, alpha: nil) else { return false }
                
        let isTooDark = brightness <= UIColor.brightnessMinThreshold
        return isTooDark
    }
}
