//
//  AppDelegate.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import UIKit
import Firebase
import FBSDKCoreKit
import GoogleSignIn

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var userInfo: NSMutableDictionary!
    var friends: NSMutableArray!
    
    //store the device id
    let deviceId = UIDevice.current.identifierForVendor?.uuidString
    
    var dataBaseRef: FIRDatabaseReference! {
        
        return FIRDatabase.database().reference()
    }
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        application.statusBarStyle = .lightContent
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.darkGray], for: .normal)
        UITabBarItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName: UIColor.white], for: .selected)
        
    
        FIRApp.configure()
        logUser()
        
        GIDSignIn.sharedInstance().clientID = FIRApp.defaultApp()?.options.clientID
        
        
        FBSDKApplicationDelegate.sharedInstance().application(application, didFinishLaunchingWithOptions: launchOptions)
        
        return true
    }

    func logUser() {
        
       if FIRAuth.auth()!.currentUser != nil {

            self.getUserInfo(uid: (FIRAuth.auth()!.currentUser?.uid)!)
            
            let tabBar = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "TabBar") as! UITabBarController
            self.window?.rootViewController = tabBar
        }
        
    }
    
    func application(_ app: UIApplication, open url: URL, options: [UIApplicationOpenURLOptionsKey : Any] = [:]) -> Bool {
        
        let handled = FBSDKApplicationDelegate.sharedInstance().application(app, open: url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String!, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        GIDSignIn.sharedInstance().handle(url, sourceApplication: options[UIApplicationOpenURLOptionsKey.sourceApplication] as! String, annotation: options[UIApplicationOpenURLOptionsKey.annotation])
        
        return handled
    }
    
    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and throttle down OpenGL ES frame rates. Games should use this method to pause the game.
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the inactive state; here you can undo many of the changes made on entering the background.
        
        if FIRAuth.auth()?.currentUser?.uid != nil{
            
            self.getUserInfo(uid: (FIRAuth.auth()!.currentUser?.uid)!)
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        if FIRAuth.auth()?.currentUser != nil{
            
            //create a reference to the database
            let myConnectionsRef = FIRDatabase.database().reference(withPath: "\(kUsers)/\((FIRAuth.auth()?.currentUser?.uid)!)/\(kConnections)/\(appDelegate.deviceId!))")
            
            //when user logs out, set the value to false
            myConnectionsRef.child(kOnline).setValue(false)
            myConnectionsRef.child(kLastOnline).setValue(NSNumber(value: Int(Date().timeIntervalSince1970)))
        }
    }
    
    //MARK: - Functions -
    func getUserInfo(uid: String) {
        
        let userRef = dataBaseRef.child(kUsers).child(uid)
        
        userRef.observeSingleEvent(of: .value, with: { (userSnap) in
            
            print(userSnap)
            if userSnap.exists() {
                appDelegate.userInfo = userSnap.value as! NSMutableDictionary
            }
        })
    }
    
    func addLabel(toView: UIView, text: String) {
        
        for view in toView.subviews{
            if view is UILabel, view.tag == 101{
                view.removeFromSuperview()
            }
        }
        
        let label = UILabel(frame: CGRect(x: 0, y: 125, width: UIScreen.main.bounds.width, height: 30))
        label.tag = 101
        //label.translatesAutoresizingMaskIntoConstraints = false
        label.text = text
        label.textAlignment = .center
        label.font = UIFont(name: "Avenir Next Ultra Light", size: 20)
        
        //label.leftAnchor.constraint(equalTo: toView.leftAnchor).isActive = true
        //label.rightAnchor.constraint(equalTo: toView.rightAnchor).isActive = true
        //label.heightAnchor.constraint(equalToConstant: 30).isActive = true
        //label.centerXAnchor.constraint(equalTo: toView.centerXAnchor).isActive = true
        //label.centerYAnchor.constraint(equalTo: toView.centerYAnchor).isActive = true
        label.adjustsFontSizeToFitWidth = true
        label.backgroundColor = UIColor.lightText
        toView.addSubview(label)
        label.bringSubview(toFront: toView)
    }
    
    func removeLabel(fromView: UIView) {
        
        if let label = fromView.viewWithTag(101){
            label.removeFromSuperview()
        }
    }
    
    //MARK: - Loader Hide/Show  -
    func showLoader()
    {
        // hideLoader()
        //BaseVC.sharedInstance.DLog("Method called")
        let imgListArray :NSMutableArray = []
        
        //use for loop
        for position in 1...3
        {
            
            let strImageName : String = "\(position).png"
            let image  = UIImage(named:strImageName)
            imgListArray.add(image!)
        }
        
        let imageView = UIImageView(frame: CGRect(x: 0, y: 0, width: 75, height: 25));
        
        imageView.animationImages = NSArray(array: imgListArray) as? [UIImage]
        imageView.animationDuration = 1.0
        imageView.startAnimating()
        
        if (!JTProgressHUD.isVisible())
        {
            JTProgressHUD.show(with: imageView)
        }
    }
    
    func hideLoader()
    {
        JTProgressHUD.hide()
        
        DispatchQueue.main.async {
            
        }
    }
}

