//
//  UsersTableViewController.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import UIKit
import Firebase

class UsersTableViewController: UITableViewController,UIAlertViewDelegate {

    var dataBaseRef: FIRDatabaseReference! {
        
        return FIRDatabase.database().reference()
    }
    
    var storageRef: FIRStorage {
        
        return FIRStorage.storage()
    }
    
    var users = [User]()
    var requests =  [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "USERS"
        self.tableView.allowsSelection = false
        
        observeRequests()
        self.perform(#selector(UsersTableViewController.observeUsers), with: nil, afterDelay: 2.0)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.requests = []
    }

    //MARK: - Function -
    func observeUsers(){
        
        let usersRef = dataBaseRef.child(kUsers)
        usersRef.observe(.value, with: { (snapshot) in
            
            if snapshot.exists(){
                
                var allUsers = [User]()
                
                for user in snapshot.children {
                    
                    let myself = User(snapshot: user as! FIRDataSnapshot)
                    
                    if myself.username != FIRAuth.auth()?.currentUser?.displayName {
                        
                        let newUser = User(snapshot: user as! FIRDataSnapshot)
                        
                        if let email = newUser.email {
                            
                            if !self.requests.contains(email){
                                allUsers.append(newUser)
                                appDelegate.removeLabel(fromView: self.view)
                            }
                        }
                    }
                }
                self.users = allUsers
                
                allUsers.sort(by: { (user1, user2) -> Bool in
                    
                    user1.username! < user2.username!
                })
                
                /*var array = NSArray()
                array = self.users as NSArray
                var marr = NSMutableArray()
                marr = array.mutableCopy() as! NSMutableArray
                let descriptor: NSSortDescriptor = NSSortDescriptor(key: "username", ascending: true)
                let newArray = marr.sort(using: [descriptor])
                //let newArray = array.sortedArray(using: [descriptor])
                print(newArray)*/
                self.users = allUsers
                
                self.tableView.reloadData()
                
                if self.users.count == 0{
                    appDelegate.removeLabel(fromView: self.view)
                    appDelegate.addLabel(toView: self.view, text: "No users.")
                }
            }
        }) { (error) in
            showAlert(controller: self, message: error.localizedDescription, title: "😁OOPS😁")
        }
    }

    func observeRequests(){
        
        appDelegate.addLabel(toView: self.view, text: "Fetching users...")
        
        let acceptedRef = dataBaseRef.child(kUserRequests).child(kAccepted).child((FIRAuth.auth()?.currentUser?.uid)!)
        
        acceptedRef.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            self.dataBaseRef.child(kUsers).child(userId).observe(.value, with: { (snapshot) in
                
                if snapshot.exists(){
                    
                    let user = User(snapshot: snapshot)
                    self.requests.append(user.email!)
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
        let sentRef = dataBaseRef.child(kUserRequests).child(kSent).child((FIRAuth.auth()?.currentUser?.uid)!)

        sentRef.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            self.dataBaseRef.child(kUsers).child(userId).observe(.value, with: { (snapshot) in
                
                if snapshot.exists(){
                    
                    let user = User(snapshot: snapshot)
                    self.requests.append(user.email!)
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
        let receivedRef = dataBaseRef.child(kUserRequests).child(kReceived).child((FIRAuth.auth()?.currentUser?.uid)!)
        
        receivedRef.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            self.dataBaseRef.child(kUsers).child(userId).observe(.value, with: { (snapshot) in
                
                if snapshot.exists(){
                    
                    let user = User(snapshot: snapshot)
                    self.requests.append(user.email!)
                }
                
            }, withCancel: nil)
            
        }, withCancel: nil)
    }
    
    //MARK: - Action -
    @IBAction func sendAction(sender: UIButton){
        
        let indexPath = NSIndexPath(row: sender.tag, section: 0)
        
        let user = users[indexPath.row]
        
        let requestRef = dataBaseRef.child(kRequests).childByAutoId()
        let requestInfo = [kFromId: (FIRAuth.auth()?.currentUser?.uid)! as AnyObject, kToId: user.uid as AnyObject] as [String: AnyObject]
        
        requestRef.setValue(requestInfo){ (error,ref) in
            
            if error != nil{
                
                print("Error: ", error?.localizedDescription ?? "")
                return
            }
            
            showAlert(controller: self, message: "You successfully sent a friend request to \(user.username!).", title: kApplicationName)
            
            //let requestId = ref.key
            
            let sentRef = self.dataBaseRef.child(kUserRequests).child(kSent).child((FIRAuth.auth()?.currentUser?.uid)!)
            sentRef.updateChildValues([user.uid!: 1])
            
            let receivedRef = self.dataBaseRef.child(kUserRequests).child(kReceived).child(user.uid!)
            receivedRef.updateChildValues([(FIRAuth.auth()?.currentUser?.uid)!: 1])
            
            self.users.remove(at: indexPath.row)
            self.tableView.deleteRows(at: [indexPath as IndexPath], with: .right)
            
            if self.users.count == 0{
                appDelegate.addLabel(toView: self.view, text: "No users.")
            }
            //this will crash because of background thread, so lets call this on dispatch_async main thread
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
            
            //showAlert(controller: self, message: "You successfully sent a friend request to \(user.username).", style: .alert)
        }
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
       
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "sendRequestCell", for: indexPath) as! UserSendRequestCell

        // Configure the cell...
        let user = users[(indexPath as NSIndexPath).row]
        
        cell.usernameLabel.text = user.username
        cell.userCountryLabel.text = user.country
        
        if users[(indexPath as NSIndexPath).row].profileImageUrl != nil
        {
            cell.userImageView.loadImageUsingCacheWithUrlString(urlString: user.profileImageUrl!)
        }
        
        cell.sendButton.addTarget(self, action: #selector(sendAction(sender:)), for: .touchUpInside)
        cell.sendButton.tag = indexPath.row
        cell.sendButton.isExclusiveTouch = true
        
        return cell
    }
}
