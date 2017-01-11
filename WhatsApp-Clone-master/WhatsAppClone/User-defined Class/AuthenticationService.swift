//
//  AuthenticationService.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import Foundation
import Firebase

struct AuthenticationService {
    
    var databaseRef: FIRDatabaseReference! {
        
        return FIRDatabase.database().reference()
    }
    
    var storageRef: FIRStorageReference! {
        
        return FIRStorage.storage().reference()
    }
    
    // 3 - We save the user info in the Database
    fileprivate func saveInfo(_ user: FIRUser!, username: String, password: String, country: String, countryCode: String, biography: String, isFromSocialLogin: Bool){
        
        let userInfo = [kEmail: user.email!, kUserName: username, kCountry: country, kCountryCode: countryCode, kBiography: biography, kUid: user.uid, kProfileImageUrl: String(describing: user.photoURL!)]
        
        let userRef = databaseRef.child(kUsers).child(user.uid)
        
        userRef.setValue(userInfo)
        
        appDelegate.hideLoader()
        
        if isFromSocialLogin == true{
            
            let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
            appDel.logUser()
        } else {
            
            signIn(user.email!, password: password)
        }
    }
    
    // 4 - We sign in the User
    func signIn(_ email: String, password: String){
        FIRAuth.auth()?.signIn(withEmail: email, password: password, completion: { (user, error) in
            if error == nil {
              
                if let user = user {
                    
                    print("\(user.displayName!) has signed in successfuly")
                  
                    let appDel: AppDelegate = UIApplication.shared.delegate as! AppDelegate
                    appDel.logUser()
                }
                
            }else {
                
                let alertView =  SCLAlertView()
                alertView.showError("😁OOPS😁", subTitle: error!.localizedDescription)
            }
        })
    }
    
    // 1 - We create firstly a New User
    func signUp(_ email: String, username: String, password: String, country: String, countryCode: String, biography: String, data: Data!, isFromSocialLogin: Bool){
        
        FIRAuth.auth()?.createUser(withEmail: email, password: password, completion: { (user, error) in
            if error == nil {
                
                self.setUserInfo(user, username: username, password: password, country: country, countryCode: countryCode, biography: biography, data: data, isFromSocialLogin: isFromSocialLogin)
                
            }else {
                
                let alertView =  SCLAlertView()
                alertView.showError("😁OOPS😁", subTitle: error!.localizedDescription)
            }
        })
        
    }
    
    func resetPassword(_ email: String){
        
        FIRAuth.auth()?.sendPasswordReset(withEmail: email, completion: { (error) in
            if error == nil {
                
                DispatchQueue.main.async(execute: { 
                    let alertView =  SCLAlertView()
                    
                    alertView.showSuccess("Resetting Password", subTitle: "An email containing the different information on how to reset your password has been sent to \(email)")
                })
            }else {
                
                let alertView =  SCLAlertView()
                alertView.showError("😁OOPS😁", subTitle: error!.localizedDescription)
            }
        })
    }
    
    // 2 - We set the User Info
    func setUserInfo(_ user: FIRUser!, username: String, password: String, country: String, countryCode: String, biography: String, data: Data!, isFromSocialLogin: Bool){
        
        let imagePath = "\(kUserProfileImages)/\(user.uid).jpg"
        
        let imageRef = storageRef.child(imagePath)
        
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        imageRef.put(data, metadata: metadata) { (metadata, error) in
            if error == nil {
                
                let changeRequest = user.profileChangeRequest()
                changeRequest.displayName = username
                
                if let photoURL = metadata!.downloadURL(){
                    changeRequest.photoURL = photoURL
                }
                
                changeRequest.commitChanges(completion: { (error) in
                    if error == nil {
                        
                        self.saveInfo(user, username: username, password: password, country: country, countryCode: countryCode, biography: biography, isFromSocialLogin: isFromSocialLogin)
                    }
                    else {
                        appDelegate.hideLoader()
                        
                        let alertView =  SCLAlertView()
                        alertView.showError("😁OOPS😁", subTitle: error!.localizedDescription)
                    }
                })
            }else {
                
                appDelegate.hideLoader()
                
                let alertView =  SCLAlertView()
                alertView.showError("😁OOPS😁", subTitle: error!.localizedDescription)
            }
        }
    }
}
