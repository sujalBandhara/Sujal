//
//  UsersTableViewCell.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit

class UsersTableViewCell: UITableViewCell {

    @IBOutlet weak var userCountryLabel: UILabel!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var groupAdminLabel: UILabel?
    @IBOutlet weak var userImageView: CustomizableImageView!
    
    override func awakeFromNib() {
        super.awakeFromNib()
        // Initialization code
        
        self.groupAdminLabel?.layer.borderColor = UIColor.init(red: 45.0/255.0, green: 155.0/255.0, blue: 213.0/255.0, alpha: 1.0).cgColor
        self.groupAdminLabel?.layer.borderWidth = 0.5
        self.groupAdminLabel?.layer.cornerRadius = 5.0
    }
}
