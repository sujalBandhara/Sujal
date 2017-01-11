//
//  CGSize.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import CoreGraphics

extension CGSize {
    
    func inverted() -> CGSize {
        
        return CGSize(width: self.height, height: self.width)
    }
}
