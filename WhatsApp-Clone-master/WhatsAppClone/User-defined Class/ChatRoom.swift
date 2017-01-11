//
//  ChatRoom.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import Foundation
import FirebaseDatabase

struct ChatRoom {
    
    var username: String!
    var other_Username: String!
    var userId: String!
    var other_UserId: String!
    var members: [String]!
    var chatRoomId: String!
    var ref: FIRDatabaseReference!
    var key: String!
    
    init(username:String,other_Username: String,userId: String,other_UserId: String,members: [String],chatRoomId: String,key: String = ""){
        
        self.username = username
        self.other_Username = other_Username
        self.userId = userId
        self.other_UserId = other_UserId
        self.members = members
        self.chatRoomId = chatRoomId
        self.ref = FIRDatabase.database().reference()
            }
    
    init (snapshot: FIRDataSnapshot){
        
        self.username = snapshot.value(forKey: "username") as! String
        self.other_Username = snapshot.value(forKey: "other_Username") as! String
        self.userId = snapshot.value(forKey: "userId") as! String
        self.other_UserId = snapshot.value(forKey: "other_UserId") as! String
        self.chatRoomId = snapshot.value(forKey: "chatRoomId") as! String
        self.members = snapshot.value(forKey: "members") as! [String]
        
        self.ref = snapshot.ref
        self.key = snapshot.key
        
    }
    
    func toAnyObject()-> [String: AnyObject] {
        
        return ["username": username as AnyObject, "other_Username": other_Username as AnyObject,"userId": userId as AnyObject, "other_UserId": other_UserId as AnyObject,"chatRoomId":chatRoomId as AnyObject,"members":members as AnyObject]
    }
}
