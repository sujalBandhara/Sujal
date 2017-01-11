//
//  CGRect.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit


extension CGRect {

    init(x: CGFloat, y: CGFloat, width: CGFloat, height: CGFloat) {

        self = CGRect(origin: CGPoint(x: x, y: y), size: CGSize(width: width, height: height))
    }

    static var one: CGRect {

        return CGRect(x: 0, y: 0, width: 1, height: 1)
    }
}

