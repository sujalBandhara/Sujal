//
//  User.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit
import Firebase

struct User {
    
    var uid: String?
    var username: String?
    var email: String?
    var biography: String?
    var country: String?
    var countryCode: String?
    var profileImageUrl: String?
    var connections: NSDictionary?
    var isOnline: Bool?
    var lastOnline: NSNumber?
    
    var ref: FIRDatabaseReference?
    var key: String
    
    init(snapshot: FIRDataSnapshot){
        
        key = snapshot.key
        ref = snapshot.ref
        
        var dict : NSMutableDictionary = NSMutableDictionary()
        
        dict = snapshot.value as! NSMutableDictionary
        
        username = dict.value(forKeyPath: kUserName) as? String
        email = dict.value(forKeyPath: kEmail) as? String
        country = dict.value(forKeyPath: kCountry) as? String
        countryCode = dict.value(forKeyPath: kCountryCode) as? String
        biography = dict.value(forKeyPath: kBiography) as? String
        profileImageUrl = dict.value(forKeyPath: kProfileImageUrl) as? String
        connections = dict.value(forKey: kConnections) as? NSDictionary
        
        if connections != nil{
            for (deviceId,connection) in connections!{
                
                if (connection as AnyObject).value(forKey: kOnline) as! Bool{
                    isOnline = true
                    lastOnline = (connection as AnyObject).value(forKey: kLastOnline) as? NSNumber
                } else {
                    if isOnline != true{
                        isOnline = false
                        lastOnline = (connection as AnyObject).value(forKey: kLastOnline) as? NSNumber
                    }
                }
            }
        }
        
        //isOnline = dict.value(forKey: kOnline) as? String
        //lastOnline = dict.value(forKey: kLastOnline) as? NSNumber
        uid = dict.value(forKeyPath: kUid) as? String
    }
}
