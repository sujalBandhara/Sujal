//
//  GroupInfoViewController.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit
import Firebase

class GroupInfoViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: - Outlets -
    @IBOutlet weak var groupImageView: CustomizableImageView!
    @IBOutlet weak var lblGroupName: UILabel!
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - User-defined Variables -
    var groupKey: String!
    var groupName: String!
    var users = [User]()
    var adminId: String!
    
    //fileprivate lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://bypt-chat-app.appspot.com")
    private lazy var groupRef: FIRDatabaseReference = FIRDatabase.database().reference().child(kGroups)
    
    var storageRef: FIRStorage {
        
        return FIRStorage.storage()
    }
    
    //MARK: - View Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelection = true
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.tableView.register(UITableViewCell.self, forCellReuseIdentifier: "addPeople")
        
        self.observeGroupInfo()
    }
    
    //MARK; -  Function -
    func observeGroupInfo(){
        
        self.lblGroupName.text = groupName
        
        self.users.sort(by: { (user1, user2) -> Bool in
            (user1.username?.lowercased())! < (user2.username?.lowercased())!
        })
        
        groupRef.child(groupKey).observe(.value, with: {(snapshot) in
            
            if snapshot.exists(){
                
                let group = Group(snapshot: snapshot)
                
                self.adminId = group.creatorId
                
                if let groupImgUrl = group.groupImageUrl {
                    
                    self.groupImageView.loadImageUsingCacheWithUrlString(urlString: groupImgUrl)
                }
            }
        })
    }
    
    //MARK: - Table view data source -
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return users.count+1
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.row == 0{
            if users.count > 0{
                return 70
            } else { return 0 }
        }
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if indexPath.row == 0{
            
            if FIRAuth.auth()?.currentUser?.uid == self.adminId{
                
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "AddPeopleViewController") as! AddPeopleViewController
                vc.users = self.users
                self.navigationController?.pushViewController(vc, animated: true)
                
            } else {
                showAlert(controller: self, message: "You can not add people to this group as you are not an admin.", title: kApplicationName)
            }
            tableView.deselectRow(at: indexPath, animated: true)
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        if indexPath.row == 0{
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "addPeople", for: indexPath)
            
            cell.textLabel?.text = "Add People"
            cell.imageView?.image = UIImage(named: "add_people_icon")
            
            return cell
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "usersCell", for: indexPath) as! UsersTableViewCell
            
            let user =  users[(indexPath as NSIndexPath).row-1]
            
            // Configure the cell...
            cell.usernameLabel.text = user.username
            cell.userCountryLabel.text = user.country
            
            if user.uid ==  self.adminId{
                cell.groupAdminLabel?.isHidden = false
            } else {
                cell.groupAdminLabel?.isHidden = true
            }
            
            if user.profileImageUrl != nil
            {
                cell.userImageView.loadImageUsingCacheWithUrlString(urlString: user.profileImageUrl!)
            }
            
            cell.selectionStyle = .none
            
            return cell
        }
    }
}
