//
//  ImageFadeInHandler.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import Foundation

final class ImageFadeInHandler {
    
    fileprivate var presentedImages: [Int] = []
    
    func addPresentedImageIndex(_ index: Int) {
        
       presentedImages.append(index)
    }
    
    func wasPresented(_ index: Int) -> Bool {
        
        return presentedImages.contains(index)
    }
}
