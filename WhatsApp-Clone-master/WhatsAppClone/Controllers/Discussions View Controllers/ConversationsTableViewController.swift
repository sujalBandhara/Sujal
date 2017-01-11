//
//  ConversationsTableViewController.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import UIKit
import Firebase

class ConversationsTableViewController: UITableViewController {

    //MARK: - User-defined Variables -
    var receiverId: String?
    var receiverIds: [String]?
    var receiverDisplayName: String?
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    var timer: Timer?
    var isFromFriend: Bool?
    
    var databaseRef: FIRDatabaseReference! {
        
        return FIRDatabase.database().reference()
    }
    
    var storageRef: FIRStorageReference! {
        
        return FIRStorage.storage().reference()
    }
    
    //MARK: - View LifeCycle -
    override func viewDidLoad() {
        super.viewDidLoad()

        observeUserMessages()
        self.perform(#selector(ConversationsTableViewController.displayMsg), with: nil, afterDelay: 0.9)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    //MARK: - Functions - 
    func observeUserMessages() {
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        appDelegate.addLabel(toView: self.view, text: "Fetching discussions...")
        
        let ref = databaseRef.child(kUserMessages).child(uid)
        ref.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            self.databaseRef.child(kUserMessages).child(uid).child(userId).observe(.childAdded, with: { (snapshot) in
                
                let messageId = snapshot.key
                self.fetchMessageWithMessageId(messageId, ref: self.databaseRef.child(kChatRooms).child(kMessages).child(messageId))
                
            }, withCancel: nil)
            
        }, withCancel: nil)
        
        ref.observe(.childRemoved, with: { (snapshot) in
            print(snapshot.key)
            print(self.messagesDictionary)
            
            self.messagesDictionary.removeValue(forKey: snapshot.key)
            self.attemptReloadOfTable()
            
            showAlert(controller: self, message: "Discussion deleted successfully.", title: kApplicationName)
            
            if self.messagesDictionary.count == 0{
                appDelegate.addLabel(toView: self.view, text: "No discussions")
            }
        }, withCancel: nil)
    }
    
    fileprivate func fetchMessageWithMessageId(_ messageId: String, ref: FIRDatabaseReference) {
        
        //let messagesReference = databaseRef.child(kChatRooms).child(kMessages).child(messageId)
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.exists(){
                
                appDelegate.removeLabel(fromView: self.view)
                
                let message = Message(snapshot: snapshot)
                
                if message.isGroupMessage == kYES {
                    self.messagesDictionary[message.toId!] = message
                } else {
                    if let chatPartnerId = message.chatPartnerId() {
                        self.messagesDictionary[chatPartnerId] = message
                    }
                }
                
                self.attemptReloadOfTable()
            }
        }, withCancel: nil)
    }
    
    fileprivate func attemptReloadOfTable() {
        self.timer?.invalidate()
        
        self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
    }
    
    func handleReloadTable() {
        self.messages = Array(self.messagesDictionary.values)
        self.messages.sort(by: { (message1, message2) -> Bool in
            
            return (message1.timestamp?.int32Value)! > (message2.timestamp?.int32Value)!
        })
        
        //this will crash because of background thread, so lets call this on dispatch_async main thread
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
    func displayMsg(){
        
        if self.messages.count == 0{
            appDelegate.removeLabel(fromView: self.view)
            appDelegate.addLabel(toView: self.view, text: "No discussions.")
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showchat1" {
            
            let chatViewController = segue.destination as! ChatViewController
            chatViewController.senderId = FIRAuth.auth()!.currentUser!.uid
            chatViewController.senderDisplayName = FIRAuth.auth()!.currentUser!.displayName!
            chatViewController.receiverId = self.receiverId
            chatViewController.receiverIds = self.receiverIds
            chatViewController.receiverDisplayName = self.receiverDisplayName
            chatViewController.isFromFriend = self.isFromFriend
        }
    }
    
    // MARK: - Table view data source

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return messages.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "conversationsCell", for: indexPath) as! ConversationsTableViewCell
        
        // Configure the cell...
        
        let message = messages[(indexPath as NSIndexPath).row]
        
        cell.usernameLabel.text = message.fromId
        cell.lastMessageLabel.text = message.text
        
            var ref = FIRDatabaseReference()
            
            if message.isGroupMessage == kYES{
                
                //if let id = message.toId? as String{
                    
                    ref = databaseRef.child(kGroups).child(message.toId!)
                    
                    ref.observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        if let dictionary = snapshot.value as? [String: AnyObject] {
                            cell.usernameLabel.text = dictionary[kGroupName] as? String
                            
                            if let profileImageUrl = dictionary[kGroupImageUrl] as? String {
                                cell.userImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
                            }
                        }
                        
                    }, withCancel: nil)
                //}
            } else {
                
                if let id = message.chatPartnerId() {
                    
                    ref = databaseRef.child(kUsers).child(id)
                    
                    ref.observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        if let dictionary = snapshot.value as? [String: AnyObject] {
                            cell.usernameLabel.text = dictionary[kUserName] as? String
                            
                            if let profileImageUrl = dictionary[kProfileImageUrl] as? String {
                                cell.userImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
                            }
                        }
                        
                    }, withCancel: nil)
                }
            }
        
        
        if let seconds = message.timestamp?.doubleValue {
            let timestampDate = Date(timeIntervalSince1970: seconds)
            
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "hh:mm a, dd-MM-yyyy"
            cell.dateLabel.text = dateFormatter.string(from: timestampDate)
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let message = messages[(indexPath as NSIndexPath).row]
        
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        
        let ref: FIRDatabaseReference
        
        if message.isGroupMessage == kYES{
            
            ref = databaseRef.child(kGroups).child(message.toId!)
            
        } else {
            
            ref = databaseRef.child(kUsers).child(chatPartnerId)
        }
        
        ref.observeSingleEvent(of: .value, with: { (snapshot) in
            guard let dictionary = snapshot.value as? [String: AnyObject] else {
                return
            }
            
            if message.isGroupMessage == kYES{
                self.receiverId = dictionary[kGroupId] as? String
                self.receiverIds =  dictionary[kGroupMembers] as? [String]
                self.receiverDisplayName = dictionary[kGroupName] as? String
                self.isFromFriend = false
            } else {
                self.receiverId = dictionary[kUid] as? String
                self.receiverDisplayName = dictionary[kUserName] as? String
                self.isFromFriend = true
            }
            self.performSegue(withIdentifier: "showchat1", sender: self)
            
        }, withCancel: nil)
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }
    
    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        guard let uid = FIRAuth.auth()?.currentUser?.uid else {
            return
        }
        
        let message = self.messages[(indexPath as NSIndexPath).row]
        
        if message.isGroupMessage == kYES{
            
            databaseRef.child(kUserMessages).child(uid).child(message.toId!).removeValue(completionBlock: { (error, ref) in
                
                if error != nil {
                    print("Failed to delete message:", error as Any)
                    return
                }
                
                self.messagesDictionary.removeValue(forKey: message.toId!)
                self.attemptReloadOfTable()
                
                //                //this is one way of updating the table, but its actually not that safe..
                //                self.messages.removeAtIndex(indexPath.row)
                //                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                
            })
            
        } else {
            
            if let chatPartnerId = message.chatPartnerId() {
                databaseRef.child(kUserMessages).child(uid).child(chatPartnerId).removeValue(completionBlock: { (error, ref) in
                    
                    if error != nil {
                        print("Failed to delete message:", error as Any)
                        return
                    }
                    
                    self.messagesDictionary.removeValue(forKey: chatPartnerId)
                    self.attemptReloadOfTable()
                    
                    //                //this is one way of updating the table, but its actually not that safe..
                    //                self.messages.removeAtIndex(indexPath.row)
                    //                self.tableView.deleteRowsAtIndexPaths([indexPath], withRowAnimation: .Automatic)
                    
                })
            }
        }
    }
}
