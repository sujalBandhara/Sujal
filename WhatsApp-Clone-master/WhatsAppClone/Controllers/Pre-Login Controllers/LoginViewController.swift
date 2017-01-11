//
//  ViewController.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit
import FBSDKLoginKit
import GoogleSignIn
import Firebase

class LoginViewController: UIViewController, UITextFieldDelegate, FBSDKLoginButtonDelegate, GIDSignInDelegate, GIDSignInUIDelegate {

    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var loginView: UIView!
    
    var authService = AuthenticationService()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        //Setting the delegates for the Textfields
        usernameTextField.delegate = self
        passwordTextField.delegate = self
        
        // Creating Tap Gesture to dismiss Keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard(_:)))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        
        // Creating Swipe Gesture to dismiss Keyboard
        let swipDown = UISwipeGestureRecognizer(target: self, action: #selector(LoginViewController.dismissKeyboard(_:)))
        swipDown.direction = .down
        view.addGestureRecognizer(swipDown)
        
        GIDSignIn.sharedInstance().delegate = self
        
        setupFacebookButtons()
        setupGoogleButtons()
        
        view.bringSubview(toFront: loginView)
    }

    //MARK: - Action -
    @IBAction func fbLoginClicked(sender: UIButton){
        
        //this is because of error code 304
        FBSDKLoginManager().logOut()
        
        FBSDKLoginManager().logIn(withReadPermissions: ["email","public_profile","user_birthday","user_friends","user_location","user_hometown"], from: self) {(result,error) in
            
            appDelegate.showLoader()
            
            if error != nil{
                print("Custom FB login failed:", error?.localizedDescription ?? "")
                appDelegate.hideLoader()
                return
            }
            
            if result!.isCancelled{
                appDelegate.hideLoader()
                return
            }
            
            if result!.grantedPermissions.contains(kEmail){
                self.showEmailAddress()
            }
        }
    }
    
    @IBAction func googleLoginClicked(sender: UIButton){
        
        GIDSignIn.sharedInstance().signOut()
        
        GIDSignIn.sharedInstance().signIn()
    }
    
    @IBAction func twitterLoginClicked(sender: UIButton){
        
        showAlert(controller: self, message: "Under Implementation.", title: "Alert")
    }
    
    //MARK: - FBSDK Login Delegate -
    func loginButton(_ loginButton: FBSDKLoginButton!, didCompleteWith result: FBSDKLoginManagerLoginResult!, error: Error!) {
        
        if error != nil {
            print("Error: ",error.localizedDescription)
            return
        }
        
        print("Successfully logged-in facebook.")
        
        showEmailAddress()
    }
    
    func loginButtonDidLogOut(_ loginButton: FBSDKLoginButton!) {
        
        print("Did log out of facebook.")
    }
    
    func showEmailAddress(){
    
        let accessToken = FBSDKAccessToken.current()

        guard let accessTokenString = accessToken?.tokenString else {
            appDelegate.hideLoader()
            return
        }
        
        let credentials = FIRFacebookAuthProvider.credential(withAccessToken: accessTokenString)
        
        FIRAuth.auth()?.signIn(with: credentials, completion: { (user, error) in
            
            if error != nil{
                showAlert(controller: self, message: error!.localizedDescription, title: "😬OOPS😬")
                appDelegate.hideLoader()
                return
            }
            
            print("Successfully created a firebase user using FB Login")
            
            FBSDKGraphRequest.init(graphPath: "/me", parameters: ["fields": "id, name, email,first_name,last_name,gender,birthday,hometown,location,picture.type(large)"]).start { (connection, result, error) in
                
                if error != nil{
                    print("Failed to start graph request:", error?.localizedDescription ?? "")
                    appDelegate.hideLoader()
                    return
                }
                
                print(result ?? "")
                
                guard let loginDict = result as? AnyObject else{
                    appDelegate.hideLoader()
                    return
                }
                
                if let imageString = ((loginDict.value(forKey: "picture") as AnyObject).value(forKey: "data") as AnyObject).value(forKey: "url"){
                    
                    let url = NSURL(string: imageString as! String)
                    
                    let data = NSData(contentsOf: url as! URL)
                    
                    //let image = UIImage(data: data as! Data)
                    
                    self.authService.setUserInfo(user, username: loginDict.value(forKey: "name") as! String, password: "", country: "", countryCode: "", biography: "", data: data as Data!, isFromSocialLogin: true)
                }
            }
        })
    }
    
    //MARK: - Google SignIn Delegate -
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error!) {
        
        appDelegate.showLoader()
        
        if error != nil{
            print("Failed to log into Google: ", error.localizedDescription)
            appDelegate.hideLoader()
            return
        }
        
        print("Successfully logged-in to Google: ", user)
        
        guard let authentication = user.authentication else {
            appDelegate.hideLoader()
            return
        }
        
        let credential = FIRGoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                          accessToken: authentication.accessToken)
        
        FIRAuth.auth()?.signIn(with: credential, completion: { (user, error) in
            
            if error != nil{
                print("Failed to create user using Google: ", error?.localizedDescription ?? "")
                appDelegate.hideLoader()
                return
            }
            
            print("Successfully created user using Google: ", user!)
            
            if let url = user?.photoURL{
                
                let data = NSData(contentsOf: url)
                
                self.authService.setUserInfo(user, username: (user?.displayName)!, password: "", country: "", countryCode: "", biography: "", data: data as Data!, isFromSocialLogin: true)
            }
        })
    }
    
    // Unwind Segue Action
    @IBAction func unwindToLogin(_ storyboard: UIStoryboardSegue){}
    
    //MARK: - Function -
    fileprivate func setupFacebookButtons(){
        
        //FB Login button using FBSDK
        /*let loginButton = FBSDKLoginButton(frame: CGRect(x: 16, y: 50, width: self.view.frame.width - 32, height: 50))
         
         loginButton.delegate = self
         /*loginButton.leftAnchor.constraint(equalTo: self.view.leftAnchor).isActive = true
         loginButton.rightAnchor.constraint(equalTo: self.view.rightAnchor).isActive = true
         loginButton.centerXAnchor.constraint(equalTo: self.view.centerXAnchor).isActive = true
         loginButton.heightAnchor.constraint(equalToConstant: 50).isActive = true
         loginButton.topAnchor.constraint(equalTo: self.view.topAnchor).isActive = true*/
         self.view.addSubview(loginButton)
         loginButton.readPermissions = ["public_profile","user_friends","user_location"]*/
        
        /*//add custom facebook login button
         let customButton = UIButton(type: .system)
         customButton.backgroundColor = .blue
         customButton.frame = CGRect(x: 16, y: 116, width: self.view.frame.width - 32, height: 50)
         customButton.setTitle("Custom FB Login", for: .normal)
         customButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
         customButton.setTitleColor(UIColor.white, for: .normal)
         customButton.addTarget(self, action: #selector(handleCustomFBLogin), for: .touchUpInside)
         self.view.addSubview(customButton)*/
    }
    
    fileprivate func setupGoogleButtons(){
        
        //add Google button  
        let googleButton = GIDSignInButton()
        googleButton.frame = CGRect(x: 16, y: 56, width: self.view.frame.width - 32, height: 50)
        //self.view.addSubview(googleButton)
        
        GIDSignIn.sharedInstance().uiDelegate = self
    }
    
    // Dismissing the Keyboard with the Return Keyboard Button
    func dismissKeyboard(_ gesture: UIGestureRecognizer){
        self.view.endEditing(true)
    }
    
    // Dismissing the Keyboard with the Return Keyboard Button
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        usernameTextField.resignFirstResponder()
        passwordTextField.resignFirstResponder()
   return true
    }
    
    // Moving the View down after the Keyboard appears
    func textFieldDidBeginEditing(_ textField: UITextField) {
        animateView(true, moveValue: 80)
    }

    // Moving the View down after the Keyboard disappears
    func textFieldDidEndEditing(_ textField: UITextField) {
        animateView(false, moveValue: 80)
    }
    
    
    // Move the View Up & Down when the Keyboard appears
    func animateView(_ up: Bool, moveValue: CGFloat){
        
        let movementDuration: TimeInterval = 0.3
        let movement: CGFloat = (up ? -moveValue : moveValue)
        UIView.beginAnimations("animateView", context: nil)
        UIView.setAnimationBeginsFromCurrentState(true)
        UIView.setAnimationDuration(movementDuration)
        self.view.frame = self.view.frame.offsetBy(dx: 0, dy: movement)
        UIView.commitAnimations()
    }
 
    // Loging in the User
    @IBAction func loginAction(_ sender: AnyObject) {
        let email = usernameTextField.text!.lowercased()
        let finalEmail = email.trimmingCharacters(in: CharacterSet.whitespaces)
        let password = passwordTextField.text!
        
        if finalEmail.isEmpty || password.isEmpty {
            self.view.endEditing(true)

            showAlert(controller: self, message: "it seems like one of the Fields is empty. Please fill all the Fields and Try Again later.", title: "😁OOPS😁")
            
        }else {
            self.view.endEditing(true)
            authService.signIn(finalEmail, password: password)
        }
    }
}

