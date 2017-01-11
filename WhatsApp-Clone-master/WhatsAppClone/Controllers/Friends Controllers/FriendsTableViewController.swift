//
//  FriendsTableViewController.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit
import Firebase

class FriendsTableViewController: UITableViewController {
    
    var receiverId: String!
    var receiverDisplayName: String!
    
    var dataBaseRef: FIRDatabaseReference! {
        
        return FIRDatabase.database().reference()
    }
    
    var storageRef: FIRStorage {
        
        return FIRStorage.storage()
    }
    
    var users = [User]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let button1 = UIBarButtonItem(image: UIImage(named: "add_friend_icon"), style: .plain, target: self, action: #selector(FriendsTableViewController.action)) // action:#selector(Class.MethodName) for swift 3
        self.navigationItem.rightBarButtonItem  = button1
        
        self.users = []
        
        self.observeFriends()
        self.perform(#selector(FriendsTableViewController.displayMsg), with: nil, afterDelay: 1.5)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
    }
    
    //MARK: - Function - 
    func observeFriends() {
        
        appDelegate.addLabel(toView: self.view, text: "Fetching friends...")
        
        let friendsRef = dataBaseRef.child(kUserRequests).child(kAccepted).child((FIRAuth.auth()?.currentUser?.uid)!)
        friendsRef.observe(.childAdded, with: { (snapshot) in
            
            if snapshot.exists(){
                
                let userId = snapshot.key
                
                self.fetchUserInfo(userId: userId)
            }
            
        }) { (error) in
            showAlert(controller: self, message: error.localizedDescription, title: "😁OOPS😁")
        }
    }
    
    func fetchUserInfo(userId: String){
        
        let userRef = self.dataBaseRef.child(kUsers).child(userId)
        
        userRef.observeSingleEvent(of: .value, with: { (usersnap) in
            
            if usersnap.exists(){
                
                appDelegate.removeLabel(fromView: self.view)
                
                let newUser = User(snapshot: usersnap)
                
                if newUser.uid != FIRAuth.auth()?.currentUser?.uid{
                    self.users.append(newUser)
                }
                
                DispatchQueue.main.async {
                    self.users.sort(by: { (user1, user2) -> Bool in
                        (user1.username?.lowercased())! < (user2.username?.lowercased())!
                    })
                    
                    let usersArray = self.users as NSArray
                    
                    appDelegate.friends = usersArray.mutableCopy() as! NSMutableArray
                    
                    self.tableView.reloadData()
                }
            }
        }){ (error) in
            showAlert(controller: self, message: error.localizedDescription, title: "😬OOPS😬")
        }
        
        self.dataBaseRef.child(kUsers).observe(.childChanged, with: { (snapshot) in
            
            if snapshot.exists(){
                
                self.users.contains(where: { (user) -> Bool in
                    user.uid! == snapshot.key
                })
                
            }
        })
    }
    
    func displayMsg(){
        
        if self.users.count == 0{
            appDelegate.removeLabel(fromView: self.view)
            appDelegate.addLabel(toView: self.view, text: "No friends.")
        }
    }
    
    //MARK: - Action -
    @IBAction func action(sender: AnyObject)
    {
        let createVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "UsersTableViewController") as? UsersTableViewController
        
        self.navigationController?.pushViewController(createVC!, animated: true)
    }
    
    //MARK: - Tableview Methods -
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return users.count
    }
    
    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        self.receiverId = users[(indexPath as NSIndexPath).row].uid!
        self.receiverDisplayName = users[(indexPath as NSIndexPath).row].username!
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        performSegue(withIdentifier: "showChat", sender: self)
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "usersCell", for: indexPath) as! UsersTableViewCell
        
        let user = users[(indexPath as NSIndexPath).row]
        // Configure the cell...
        
        cell.usernameLabel.text = user.username
        cell.userCountryLabel.text = user.country
        
        if user.profileImageUrl != nil
        {
            cell.userImageView.loadImageUsingCacheWithUrlString(urlString: user.profileImageUrl!)
        }
        
        if user.isOnline == true{
            cell.userImageView.layer.borderColor = UIColor.green.cgColor
        } else {
            cell.userImageView.layer.borderColor = UIColor.red.cgColor
        }
        
        cell.userImageView.layer.borderWidth = 1.0
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let unfriend = UITableViewRowAction(style: .normal, title: "Unfriend") { action, index in
            
            guard let uid = FIRAuth.auth()?.currentUser?.uid else {
                return
            }
            
            let user = self.users[indexPath.row]
            
            let ref = self.dataBaseRef.child(kUserRequests).child(kAccepted).child(user.uid!).child(uid)
            
            ref.removeValue { (error, ref) in
                
                if error != nil {
                    print("Failed to unfriend friend:", error as Any)
                    return
                }
                
                showAlert(controller: self, message: "You are no more friend with \(user.username!).", title: kApplicationName)
                
                self.users.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath as IndexPath], with: .left)
                
                self.tableView.reloadData()
                
                if self.users.count == 0{
                    appDelegate.addLabel(toView: self.view, text: "No friends")
                }
                
                let ref = self.dataBaseRef.child(kUserRequests).child(kAccepted).child(uid).child(user.uid!)
                
                ref.removeValue(completionBlock: { (error, ref) in
                    
                    if error != nil {
                        print("Failed to unfriend friend:", error as Any)
                        return
                    }
                })
                
                self.dataBaseRef.child(kUserMessages).child(uid).child(user.uid!).removeValue(completionBlock: { (error, ref) in
                    
                    if error != nil {
                        print("Failed to delete messages:", error as Any)
                        return
                    }
                    
                    self.dataBaseRef.child(kUserMessages).child(user.uid!).child(uid).removeValue(completionBlock: { (error, ref) in
                        
                        if error != nil {
                            print("Failed to delete messages:", error as Any)
                            return
                        }
                        //                //this is one way of updating the table, but its actually not that safe..
                        //                self.messages.removeAtIndex(indexPath.row)
                        //                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    })
                    //                //this is one way of updating the table, but its actually not that safe..
                    //                self.messages.removeAtIndex(indexPath.row)
                    //                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                })
            }
        }
        unfriend.backgroundColor = UIColor.init(red: 45.0/255.0, green: 155.0/255.0, blue: 213.0/255.0, alpha: 1.0)
        
        return [unfriend]
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let user = users[indexPath.row]
        
        let ref = dataBaseRef.child(kUserRequests).child(kAccepted).child(user.uid!).child(uid)
        
        ref.removeValue { (error, ref) in
            
            if error != nil {
                print("Failed to unfriend friend:", error as Any)
                return
            }
            
            self.users.remove(at: indexPath.row)
            self.tableView.reloadData()
            
            if self.users.count == 0{
                appDelegate.addLabel(toView: self.view, text: "No friends")
            }
            
            let ref = self.dataBaseRef.child(kUserRequests).child(kAccepted).child(uid).child(user.uid!)
            
            ref.removeValue(completionBlock: { (error, ref) in
                
                if error != nil {
                    print("Failed to unfriend friend:", error as Any)
                    return
                }
            })
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showChat" {
            
            let chatViewController = segue.destination as! ChatViewController
            chatViewController.senderId = FIRAuth.auth()!.currentUser!.uid
            chatViewController.senderDisplayName = FIRAuth.auth()!.currentUser!.displayName!
            chatViewController.receiverId = self.receiverId
            chatViewController.receiverDisplayName = self.receiverDisplayName
            chatViewController.isFromFriend = true
        }
    }   
}
