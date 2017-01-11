//
//  ChatFunctions.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import Foundation
import FirebaseDatabase
import FirebaseAuth
import Firebase

struct ChatFunctions {
    
    
    
   fileprivate var dataBaseRef: FIRDatabaseReference! {
        return FIRDatabase.database().reference()
    }
    
    func startChat(_ user1: User, user2: User)-> String{
        
        let userId1 = user1.uid
        let userId2 = user2.uid
        
        var chatRoomId: String = ""
        
        
        
        let comparison = userId1?.compare(userId2!).rawValue
        
        let members = [user1.username,user2.username]

        if comparison! < 0 {
            
            chatRoomId = userId1! + userId2!
        }else {
            chatRoomId = userId2! + userId1!

        }
        
        self.createChatRoom(user1, user2: user2, members: members as! [String], chatRoomId: chatRoomId)
        
        
        return chatRoomId
    }
    
    func createChatRoom(_ user1: User, user2: User, members: [String], chatRoomId: String){
        
        let chatRoomRef = dataBaseRef.child("ChatRooms").queryOrdered(byChild: "chatRoomId").queryEqual(toValue: chatRoomId)
        
        chatRoomRef.observe(.value , with: { (snapshot) in
            var createChatRoom = true
            
            if snapshot.exists(){
                
                for chatRoom in (snapshot.value! as AnyObject).allValues {
                    
                    if (chatRoom as AnyObject).value(forKey: "chatRoomId") as! String == chatRoomId {
                        createChatRoom = false
                        
                    }
                }
                
            }
            
            if createChatRoom {
                self.createNewChatRoom(user1, user2: user2, members: members, chatRoomId: chatRoomId)
                
            }
        })
    }
    
    
    fileprivate func createNewChatRoom(_ user1: User, user2: User, members: [String], chatRoomId: String){
        let chatRoom = ChatRoom(username: user1.username!, other_Username: user2.username!, userId: user1.uid!, other_UserId: user2.uid!, members: members, chatRoomId: chatRoomId)
        
        let chatRoomRef = dataBaseRef.child("ChatRooms").child(chatRoomId)
        chatRoomRef.setValue(chatRoom.toAnyObject())
        
        
    }
    
    
}
