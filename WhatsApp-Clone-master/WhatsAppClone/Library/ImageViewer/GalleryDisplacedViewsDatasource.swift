//
//  GalleryDisplacedViewsDatasource.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import UIKit

public protocol DisplaceableView {

    var image: UIImage? { get }
    var bounds: CGRect { get }
    var center: CGPoint { get }
    var boundsCenter: CGPoint { get }
    var contentMode: UIViewContentMode { get }
    var hidden: Bool { get set }

    func convertPoint(_ point: CGPoint, toView view: UIView?) -> CGPoint
}

public protocol GalleryDisplacedViewsDatasource: class {
    
    func provideDisplacementItem(atIndex index: Int) -> DisplaceableView?
}
