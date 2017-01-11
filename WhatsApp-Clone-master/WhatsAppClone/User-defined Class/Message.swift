//
//  Message.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import Foundation
import Firebase

struct Message {
    
    
    var fromId: String?
    var senderDisplayName: String?
    var toId: String?
    var timestamp: NSNumber?
    var text: String?
    var imageUrl: String?
    var imageWidth: NSNumber?
    var imageHeight: NSNumber?
    var videoUrl: String?
    var isGroupMessage: String?
    
    var ref: FIRDatabaseReference?
    var key: String = ""
    
    func chatPartnerId() -> String? {
        return fromId == FIRAuth.auth()?.currentUser?.uid ? toId : fromId
    }
    
    init(snapshot: FIRDataSnapshot){
        
        if snapshot.exists(){
            
            var dict : NSMutableDictionary = NSMutableDictionary()
            
            dict = snapshot.value as! NSMutableDictionary
            
            fromId = dict.value(forKey: kFromId) as? String
            toId = dict.value(forKey: kToId) as? String
            
            timestamp = dict.value(forKey: kTimestamp) as? NSNumber
            
            text = dict.value(forKey: kText) as? String
            
            imageUrl = dict.value(forKey: kImageUrl) as? String
            imageWidth = dict.value(forKey: kImageWidth) as? NSNumber
            imageHeight = dict.value(forKey: kImageHeight) as? NSNumber
            
            videoUrl = dict.value(forKey: kVideoUrl) as? String
            
            isGroupMessage = dict.value(forKey: kGroupMessage) as? String
            
            key = snapshot.key
            ref = snapshot.ref
        }
    }
    
    init(text: String, senderId: String, senderDisplayName: String, timestamp: NSNumber, key: String = ""){
        
        self.fromId = senderId
        self.senderDisplayName = senderDisplayName
        self.text = text
        self.timestamp = timestamp
    }
    
    init(senderId: String, receiverId: String, timestamp: NSNumber, text: String, key: String = ""){
        
        self.fromId = senderId
        self.toId = receiverId
        self.timestamp = timestamp
        self.text = text
    }
    
    init(senderId: String, receiverId: String, timestamp: NSNumber, imageUrl: String, imageWidth: NSNumber, imageHeight: NSNumber, key: String = ""){
        
        self.fromId = senderId
        self.toId = receiverId
        self.timestamp = timestamp
        self.imageUrl = imageUrl
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
    }
    
    init(senderId: String, receiverId: String, timestamp: NSNumber, videoUrl: String, imageUrl: String, imageWidth: NSNumber, imageHeight: NSNumber, key: String = ""){
        
        self.fromId = senderId
        self.toId = receiverId
        self.timestamp = timestamp
        self.imageUrl = imageUrl
        self.imageWidth = imageWidth
        self.imageHeight = imageHeight
        self.videoUrl = videoUrl
    }
    
    func toAnyObject() -> [String: AnyObject]{
        
        return  [kText: text as AnyObject, kFromId: fromId as AnyObject, kSenderName: senderDisplayName as AnyObject, kTimestamp: timestamp as AnyObject]
    }
    
    func toAnyObjectT() -> [String: AnyObject]{
        
        return  [kFromId: fromId as AnyObject, kToId: toId as AnyObject, kTimestamp: timestamp as AnyObject, kText: text as AnyObject]
    }
    
    func toAnyObjectP() -> [String: AnyObject]{
        
        return  [kFromId: fromId as AnyObject, kToId: toId as AnyObject, kTimestamp: timestamp as AnyObject, kImageUrl: imageUrl as AnyObject]
    }
    
    func toAnyObjectV() -> [String: AnyObject]{
        
        return  [kFromId: fromId as AnyObject, kToId: toId as AnyObject, kTimestamp: timestamp as AnyObject, kVideoUrl: videoUrl as AnyObject, kImageUrl: imageUrl as AnyObject, kImageWidth: imageWidth as AnyObject, kImageHeight: imageHeight as AnyObject]
    }
}
