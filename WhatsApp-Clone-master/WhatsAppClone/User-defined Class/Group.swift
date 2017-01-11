//
//  Group.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import Foundation
import Firebase

struct Group {
    
    var groupId: String?
    var groupName: String?
    var creatorName: String?
    var creatorId: String?
    var groupMembers: [String]?
    var createdDate: NSNumber?
    var membersCount: NSNumber?
    var groupImageUrl: String?
    
    var ref: FIRDatabaseReference?
    var key: String = ""
    
    init(snapshot: FIRDataSnapshot){
        
        key = snapshot.key
        ref = snapshot.ref
        
        var dict : NSMutableDictionary = NSMutableDictionary()
        
        dict = snapshot.value as! NSMutableDictionary
        
        groupId = dict.value(forKey: kGroupId) as? String
        groupName = dict.value(forKey: kGroupName) as? String
        creatorName = dict.value(forKey: kCreatorName) as? String
        creatorId = dict.value(forKey: kCreatoId) as? String
        createdDate = dict.value(forKey: kCreatedDate) as? NSNumber
        membersCount = dict.value(forKey: kMembersCount) as? NSNumber
        groupMembers = dict.value(forKey: kGroupMembers) as? [String]
        groupImageUrl = dict.value(forKey: kGroupImageUrl) as? String
    }
    
    init(groupName: String, creatorName: String, creatorId: String, createdDate: NSNumber, membersCount: NSNumber, key: String = ""){
        
        self.groupName = groupName
        self.creatorName = creatorName
        self.creatorId = creatorId
        self.createdDate = createdDate
        self.membersCount = membersCount
    }
    
    
    func toAnyObject() -> [String: AnyObject]{
        
        return  [kGroupName: groupName as AnyObject, kCreatorName: creatorName as AnyObject, kCreatoId: creatorId as AnyObject, kCreatedDate: createdDate as AnyObject, kMembersCount: membersCount as AnyObject]
    }
}
