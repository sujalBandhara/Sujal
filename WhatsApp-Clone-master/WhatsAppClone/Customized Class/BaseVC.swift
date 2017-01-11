//
//  BaseVC.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit

class BaseVC: UIViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    func addLabel(toView: UIView) {
        
        let label = UILabel()
        label.tag = 101
        label.translatesAutoresizingMaskIntoConstraints = false
        
        if #available(iOS 9.0, *) {
            label.leftAnchor.constraint(equalTo: toView.leftAnchor).isActive = true
            label.rightAnchor.constraint(equalTo: toView.rightAnchor).isActive = true
            label.heightAnchor.constraint(equalToConstant: 30).isActive = true
            label.centerXAnchor.constraint(equalTo: toView.centerXAnchor).isActive = true
            label.centerYAnchor.constraint(equalTo: toView.centerYAnchor).isActive = true
        } else {
            // Fallback on earlier versions
        }
        
        
        label.backgroundColor = UIColor.red
    }
    
    func removeLabel(fromView: UIView) {
        
        if let label = fromView.viewWithTag(101){
            label.removeFromSuperview()
        }
    }
}
