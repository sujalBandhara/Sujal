//
//  AddPeopleViewController.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit
import Firebase

class AddPeopleViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    //MARK: - Outlets -
    @IBOutlet weak var tableView: UITableView!
    
    //MARK: - User-defined Variables -
    var groupKey: String!
    var groupName: String!
    var users = [User]() //--> Users that are in created group
    var otherFreinds = [User]() //--> Users that are not in created group
    
    //fileprivate lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://bypt-chat-app.appspot.com")
    private lazy var groupRef: FIRDatabaseReference = FIRDatabase.database().reference().child(kGroups)
    
    var dataBaseRef: FIRDatabaseReference! {
        
        return FIRDatabase.database().reference()
    }
    
    var storageRef: FIRStorage {
        
        return FIRStorage.storage()
    }
    
    //MARK: - View Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.allowsSelection = true
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        self.observeFriends()
    }
    
    //MARK: - Function -
    func observeFriends() {
        
        appDelegate.addLabel(toView: self.view, text: "Fetching friends...")
        
        let usersArray = self.users as NSArray
        
        let users = usersArray.mutableCopy() as! NSMutableArray
        
        if appDelegate.friends != nil{
            
            appDelegate.removeLabel(fromView: self.view)
            
            return
            
        } else {
            
            let friendsRef = self.dataBaseRef.child(kUserRequests).child(kAccepted).child((FIRAuth.auth()?.currentUser?.uid)!)
            friendsRef.observe(.childAdded, with: { (snapshot) in
                
                if snapshot.exists(){
                    
                    let userId = snapshot.key
                    let userRef = self.dataBaseRef.child(kUsers).child(userId)
                    
                    userRef.observeSingleEvent(of: .value, with: { (usersnap) in
                        
                        if usersnap.exists(){
                            
                            appDelegate.removeLabel(fromView: self.view)
                            
                            let newUser = User(snapshot: usersnap)
                            
                            if newUser.uid != FIRAuth.auth()?.currentUser?.uid{
                                
                                if !users.contains(newUser){
                                    self.otherFreinds.append(newUser)
                                }
                            }
                            
                            DispatchQueue.main.async {
                                self.otherFreinds.sort(by: { (user1, user2) -> Bool in
                                    user1.username! < user2.username!
                                })
                                
                                
                                //appDelegate.friends = self.users
                                
                                self.tableView.reloadData()
                            }
                        }
                    })
                }
                
            }) { (error) in
                showAlert(controller: self, message: error.localizedDescription, title: "😁OOPS😁")
            }
        }
    }
    
    //MARK: - Table view data source -
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return users.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        //tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "usersCell", for: indexPath) as! UsersTableViewCell
        
        let user =  users[(indexPath as NSIndexPath).row]
        
        // Configure the cell...
        cell.usernameLabel.text = user.username
        cell.userCountryLabel.text = user.country
        
        if user.profileImageUrl != nil
        {
            cell.userImageView.loadImageUsingCacheWithUrlString(urlString: user.profileImageUrl!)
        }
        
        cell.selectionStyle = .none
        
        return cell
    }
}
