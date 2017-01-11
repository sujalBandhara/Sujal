//
//  UIImageView.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import UIKit

extension DisplaceableView {

    func imageView() -> UIImageView {

        let imageView = UIImageView(image: self.image)
        imageView.bounds = self.bounds
        imageView.center = self.center
        imageView.contentMode = self.contentMode

        return imageView
    }
}
