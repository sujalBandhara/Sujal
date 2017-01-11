//
//  UIView.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit

extension UIView {

    public var boundsCenter: CGPoint {

        return CGPoint(x: self.bounds.width / 2, y: self.bounds.height / 2)
    }

    func frame(inCoordinatesOfView parentView: UIView) -> CGRect {

        let frameInWindow = UIApplication.applicationWindow.convert(self.bounds, from: self)
        return parentView.convert(frameInWindow, from: UIApplication.applicationWindow)
    }

    func addSubviews(_ subviews: UIView...) {

        for view in subviews { self.addSubview(view) }
    }

    static func animateWithDuration(_ duration: TimeInterval, delay: TimeInterval, animations: @escaping () -> Void) {

        UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions(), animations: animations, completion: nil)
    }

    static func animateWithDuration(_ duration: TimeInterval, delay: TimeInterval, animations: @escaping () -> Void, completion: ((Bool) -> Void)?) {

        UIView.animate(withDuration: duration, delay: delay, options: UIViewAnimationOptions(), animations: animations, completion: completion)
    }
}

extension DisplaceableView {

    func frameInCoordinatesOfScreen() -> CGRect {

        return UIView().convert(self.bounds, to: UIScreen.main.coordinateSpace)
    }
}
