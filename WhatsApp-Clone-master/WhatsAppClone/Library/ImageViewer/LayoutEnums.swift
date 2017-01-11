//
//  HeaderFooterLayout.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import UIKit

public typealias MarginLeft = CGFloat
public typealias MarginRight = CGFloat
public typealias MarginTop = CGFloat
public typealias MarginBottom = CGFloat

/// Represents possible layouts for the close button
public enum ButtonLayout {
    
    case pinLeft(MarginTop, MarginLeft)
    case pinRight(MarginTop, MarginRight)
}

/// Represents various possible layouts for the header
public enum HeaderLayout {
    
    case pinLeft(MarginTop, MarginLeft)
    case pinRight(MarginTop, MarginRight)
    case pinBoth(MarginTop, MarginLeft, MarginRight)
    case center(MarginTop)
}

/// Represents various possible layouts for the footer
public enum FooterLayout {
    
    case pinLeft(MarginBottom, MarginLeft)
    case pinRight(MarginBottom, MarginRight)
    case pinBoth(MarginBottom, MarginLeft, MarginRight)
    case center(MarginBottom)
}
