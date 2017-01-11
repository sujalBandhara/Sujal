//
//  GalleryDatasource.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import UIKit

public protocol GalleryItemsDatasource: class {
    
    func itemCount() -> Int
    func provideGalleryItem(_ index: Int) -> GalleryItem
}
