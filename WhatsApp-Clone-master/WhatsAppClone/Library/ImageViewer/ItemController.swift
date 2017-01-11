//
//  ItemViewController.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit

typealias Duration = TimeInterval

public protocol ItemController: class {

    var index: Int { get }
    var isInitialController: Bool { get set }
    weak var delegate: ItemControllerDelegate? { get set }
    weak var displacedViewsDatasource: GalleryDisplacedViewsDatasource? { get set }

    func fetchImage()

    func presentItem(alongsideAnimation: () -> Void, completion: @escaping () -> Void)
    func dismissItem(alongsideAnimation: () -> Void, completion: @escaping () -> Void)

    func closeDecorationViews(_ duration: TimeInterval)
}
