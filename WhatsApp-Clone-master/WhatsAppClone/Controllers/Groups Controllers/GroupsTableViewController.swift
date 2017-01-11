//
//  GroupsTableViewController.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage

class GroupsTableViewController: UITableViewController {
    
    var receiverIds: [String]!
    var receiverDisplayName: String!
    var groupKey: String!
    var adminId: String?
    
    var groups = [Group]()
    var users = [User]()
    
    var dataBaseRef: FIRDatabaseReference! {
        
        return FIRDatabase.database().reference()
    }
    
    var storageRef: FIRStorage {
        
        return FIRStorage.storage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button1 = UIBarButtonItem(image: UIImage(named: "create_group_icon"), style: .plain, target: self, action: #selector(GroupsTableViewController.action)) // action:#selector(Class.MethodName) for swift 3
        self.navigationItem.rightBarButtonItem  = button1
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        self.groups = []
        observeGroups()//Check for the groups
    }
    
    @IBAction func action(sender: AnyObject)
    {
        let createVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "CreateGroupViewController") as? CreateGroupViewController
        
        self.navigationController?.pushViewController(createVC!, animated: true)
    }
    
    //MARK: - Functions -
    func observeGroups()
    {
        appDelegate.addLabel(toView: self.view, text: "No groups...! Create a new one...")
        
        let groupsRef = self.dataBaseRef.child(kGroups)
        
        if appDelegate.userInfo != nil {
            
            if appDelegate.userInfo[kGroupIds] != nil {
                
                let groupIdsArray = (appDelegate.userInfo[kGroupIds]! as! NSMutableArray)
                
                var allGroups = [Group]()
                
                for groupIdx in 0..<groupIdsArray.count {
                    
                    groupsRef.child(groupIdsArray[groupIdx] as! String).observe(.value, with: { (groupSnap) in
                        
                        if groupSnap.exists() {
                            
                            appDelegate.removeLabel(fromView: self.view)
                            
                            let myGroup = Group(snapshot: groupSnap)
                            
                            let loginId = myGroup.groupMembers?.index(of: (FIRAuth.auth()?.currentUser?.uid)! as String)
                            
                            if loginId != nil {
                                
                                if myGroup.groupMembers?[loginId!] == FIRAuth.auth()!.currentUser!.uid {
                                    
                                    allGroups.append(myGroup)
                                }
                            }
                            /*let dict = group as AnyObject
                             
                             self.groupsArray.add(dict)*/
                            
                            allGroups.sort(by: { (group1, group2) -> Bool in
                                group1.groupName!.lowercased() < group2.groupName!.lowercased()
                            })
                            
                            self.groups = allGroups
                            
                            if groupIdsArray.count == self.groups.count{
                                self.tableView.reloadData()
                            }
                        }
                    }) { (error) in
                        showAlert(controller: self, message: error.localizedDescription, title: "😁OOPS😁")                    }
                }
            }
        }
    }
    
    func observeUsers()
    {
        let usersRef = dataBaseRef.child("users")
        usersRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            var allUsers = [User]()
            
            for user in snapshot.children {
                
                let myself = User(snapshot: user as! FIRDataSnapshot)
                
                if myself.username != FIRAuth.auth()!.currentUser!.displayName! {
                    
                    let newUser = User(snapshot: user as! FIRDataSnapshot)
                    allUsers.append(newUser)
                    
                }
            }
        
            self.users = allUsers
            
            self.performSegue(withIdentifier: "showChat", sender: self)
            
        }) { (error) in
            showAlert(controller: self, message: error.localizedDescription, title: "😁OOPS😁")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showChat" {
            
            let chatViewController = segue.destination as! ChatViewController
            chatViewController.senderId = FIRAuth.auth()!.currentUser!.uid
            chatViewController.senderDisplayName = FIRAuth.auth()!.currentUser!.displayName!
            chatViewController.receiverIds = self.receiverIds
            chatViewController.receiverId = self.groupKey
            chatViewController.receiverDisplayName = self.receiverDisplayName
            chatViewController.groupKey = self.groupKey
            chatViewController.adminId = self.adminId
            chatViewController.isFromFriend = false
        }
    }
    
    // MARK: - Table view data source -
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return groups.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let group = groups[(indexPath as NSIndexPath).row]
            
        self.receiverIds = group.groupMembers!
        self.receiverDisplayName = group.groupName
        self.groupKey = group.key
        self.adminId = group.creatorId
    
        //self.observeUsers()
        
        performSegue(withIdentifier: "showChat", sender: self)
        
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "groupsCell", for: indexPath) as! GroupsTableViewCell
        
        // Configure the cell...
        
        cell.groupnameLabel.text = groups[(indexPath as NSIndexPath).row].groupName
        
        if groups[(indexPath as NSIndexPath).row].groupImageUrl != nil
        {
            storageRef.reference(forURL: groups[(indexPath as NSIndexPath).row].groupImageUrl!).data(withMaxSize: 1*1024*1024*1024) { (data, error) in
                if error == nil {
                    
                    DispatchQueue.main.async(execute: {
                        if let data = data {
                            
                            cell.groupImageView.image = UIImage(data: data)
                        }
                    })
                }else {
                    showAlert(controller: self, message: error!.localizedDescription, title: "😁OOPS😁")
                }
            }
        }
        return cell
    }
}
