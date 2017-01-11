//
//  UIViewController.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit

public extension UIViewController {
    
    public func presentImageGallery(_ gallery: GalleryViewController, completion: ((Void) -> Void)? = {}) {
        
        present(gallery, animated: false, completion: completion)
    }
}
