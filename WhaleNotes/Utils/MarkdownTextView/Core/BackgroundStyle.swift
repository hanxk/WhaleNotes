//
//  Base.swift
//  WhaleNotes
//
//  Created by hanxk on 2021/1/7.
//  Copyright © 2021 hanxk. All rights reserved.
//

import UIKit

/// Shadow style for `backgroundStyle` attribute
public class ShadowStyle {

    /// Color of the shadow
    public let color: UIColor

    /// Shadow offset
    public let offset: CGSize

    /// Shadow blur
    public let blur: CGFloat

    public init(color: UIColor, offset: CGSize, blur: CGFloat) {
        self.color = color
        self.offset = offset
        self.blur = blur
    }
}

/// Border style for `backgroundStyle` attribute
public class BorderStyle {

    /// Color of border
    public let color: UIColor

    /// Width of the border
    public let lineWidth: CGFloat

    public init(lineWidth: CGFloat, color: UIColor) {
        self.lineWidth = lineWidth
        self.color = color
    }
}

/// Style for background color attribute. Adding `backgroundStyle` attribute will add border, background and shadow
/// as per the styles specified.
/// - Important:
/// This attribute is separate from `backgroundColor` attribute. Applying `backgroundColor` takes precedence over backgroundStyle`
/// i.e. the background color shows over color of `backgroundStyle` and will not show rounded corners.
/// - Note:
/// Ideally `backgroundStyle` may be used instead of `backgroundColor` as it can mimic standard background color as well as
/// border, shadow and rounded corners.
public class BackgroundStyle {

    /// Background color
    public let color: UIColor

    /// Corner radius of the background
    public let cornerRadius: CGFloat

    /// Optional border style for the background
    public let border: BorderStyle?

    /// Optional shadow style for the background
    public let shadow: ShadowStyle?

    public init(color: UIColor, cornerRadius: CGFloat = 0, border: BorderStyle? = nil, shadow: ShadowStyle? = nil) {
        self.color = color
        self.cornerRadius = cornerRadius
        self.border = border
        self.shadow = shadow
    }
}

public class TagStyle {

    /// Background color
    public let background: UIColor
    public let forgroundColor: UIColor  =  .white

    /// Corner radius of the background
    public let cornerRadius: CGFloat
    public init(background: UIColor = UIColor.brand.withAlphaComponent(0.12), cornerRadius: CGFloat = 2) {
        self.background = background
        self.cornerRadius = cornerRadius
    }
}
