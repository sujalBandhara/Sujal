//
//  CustomizableButton.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit

@IBDesignable class CustomizableButton: UIButton {

    @IBInspectable var cornerRadius: CGFloat = 0 {
        
        didSet {
            
            layer.cornerRadius = cornerRadius
            
        }
        
    }
    
    @IBInspectable var borderWidth: CGFloat = 0 {
        
        didSet {
            
            layer.borderWidth = borderWidth
        }
        
    }
    
    @IBInspectable var borderColor: CGColor? = UIColor.white.cgColor {
        
        didSet {
            
            layer.borderColor = borderColor
        }
        
    }

}
