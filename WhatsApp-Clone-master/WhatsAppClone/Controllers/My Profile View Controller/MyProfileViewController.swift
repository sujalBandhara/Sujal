//
//  MyProfileViewController.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit
import Firebase
import FirebaseAuth
import FirebaseStorage
import FirebaseDatabase

class MyProfileViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UIAlertViewDelegate {

    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var userCountryLabel: UILabel!
    @IBOutlet weak var userEmailLabel: UILabel!
    @IBOutlet weak var userBioLabel: UILabel!
    @IBOutlet weak var userImageView: CustomizableImageView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentControl: UISegmentedControl!
    @IBOutlet weak var requestView: UIView!
    
    var dataBaseRef: FIRDatabaseReference! {
        
        return FIRDatabase.database().reference()
    }
    
    var storageRef: FIRStorage! {
        
        return FIRStorage.storage()
    }
    
    var receivedRequests = [User]()
    var sentRequests = [User]()
    var requests = [User]()
    
    var selectedIndex: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        self.tableView.allowsSelection = false
        
        //get data from firebase database and update UI
        loadUserInfo()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.segmentControl.selectedSegmentIndex = 0
        self.selectedIndex = self.segmentControl.selectedSegmentIndex
        
        //Remove objects
        self.requests = []
        self.receivedRequests = []
        self.sentRequests = []
        self.tableView.reloadData()
        
        //get requests from firebase db and update UI
        loadRequests()
    }
    
    //MARK: - Function -
    func loadUserInfo(){
        
        let userRef = dataBaseRef.child("\(kUsers)/\(FIRAuth.auth()!.currentUser!.uid)")
        userRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            if snapshot.exists(){
                
                let user = User(snapshot: snapshot)
                
                if let email = user.email{
                    
                    //check connections
                    self.manageConnections(userId: user.uid!)
                    
                    self.usernameLabel.text = user.username
                    self.userEmailLabel.text = "Email: \(email)"
                    self.userBioLabel.text = user.biography
                    
                    // create an NSMutableAttributedString that we'll append everything to
                    let fullString = NSMutableAttributedString(string: "Country: \(user.country!) ")
                    
                    if let countryCode = user.countryCode {
                        
                        // create our NSTextAttachment
                        let image1Attachment = NSTextAttachment()
                        image1Attachment.image = UIImage(named: "SwiftCountryPicker.bundle/Images/\(countryCode).png")
                        
                        // wrap the attachment in its own attributed string so we can append it
                        let image1String = NSAttributedString(attachment: image1Attachment)
                        
                        // add the NSTextAttachment wrapper to our full string, then add some more text.
                        fullString.append(image1String)
                    }
                    
                    // draw the result in a label
                    self.userCountryLabel.attributedText = fullString
                    
                    let imageURL = user.profileImageUrl
                    
                    self.storageRef.reference(forURL: imageURL!).data(withMaxSize: 1 * 1024 * 1024, completion: { (data, error) in
                        if error == nil {
                            if let data = data {
                                DispatchQueue.main.async(execute: {
                                    
                                    self.userImageView.image = UIImage(data: data)
                                })  }
                            
                        } else {
                            showAlert(controller: self, message: error!.localizedDescription, title: "😁OOPS😁")
                        }
                    })
                }
            }
            
        }) { (error) in
                showAlert(controller: self, message: error.localizedDescription, title: "😁OOPS😁")
        }
    }

    func loadRequests() {
        
        appDelegate.addLabel(toView: self.requestView, text: "No requests")
        
        let receivedRef = dataBaseRef.child(kUserRequests).child(kReceived).child((FIRAuth.auth()?.currentUser?.uid)!)
        
        receivedRef.observe(.childAdded, with: { (snapshot) in
            
            let userId = snapshot.key
            
            let userRef = self.dataBaseRef.child(kUsers).child(userId)
            
            userRef.observeSingleEvent(of: .value, with: { (userSnap) in
                
                if snapshot.exists(){
                    
                    appDelegate.removeLabel(fromView: self.requestView)
                    
                    let newUser = User(snapshot: userSnap)
                    
                    if newUser.uid != FIRAuth.auth()?.currentUser?.uid{
                        self.receivedRequests.append(newUser)
                    }
                    
                    DispatchQueue.main.async(execute: {
                        self.requests = self.receivedRequests
                        self.tableView.reloadData()
                    })
                }
            })
            
        }, withCancel: nil)
        
        let sentRef = dataBaseRef.child(kUserRequests).child(kSent).child((FIRAuth.auth()?.currentUser?.uid)!)
        
        sentRef.observe(.childAdded, with: { (snapshot) in
         
            let userId = snapshot.key
            
            let userRef = self.dataBaseRef.child(kUsers).child(userId)
            
            userRef.observeSingleEvent(of: .value, with: { (userSnap) in
                
                if snapshot.exists(){
                    
                    let newUser = User(snapshot: userSnap)
                    
                    if newUser.uid != FIRAuth.auth()?.currentUser?.uid{
                        self.sentRequests.append(newUser)
                    }
                }
            })
            
        }, withCancel: nil)
    }
    
    func manageConnections(userId: String){
        
        //create a reference to the database
        let myConnectionsRef = FIRDatabase.database().reference(withPath: "\(kUsers)/\(userId)/\(kConnections)/\(appDelegate.deviceId!))")
        
        //when user logs in, set the value to true
        myConnectionsRef.child(kOnline).setValue(true)
        myConnectionsRef.child(kLastOnline).setValue(NSNumber(value: Int(Date().timeIntervalSince1970)))
        
        //observer which will monitor if the user is logged in or out
        myConnectionsRef.observeSingleEvent(of: .value, with: { (snapshot) in
            
            guard let connected = snapshot.value as? Bool, connected else {
                return
            }
        })
    }
    
    @IBAction func indexChanged(_ segment: UISegmentedControl) {
        
        self.requests = []
        
        if segment.selectedSegmentIndex == 0 {
            
            selectedIndex = segment.selectedSegmentIndex
            self.requests = self.receivedRequests
        }
        else{
            selectedIndex = segment.selectedSegmentIndex
            self.requests = self.sentRequests
        }
        
        if self.requests.count > 0 {
            appDelegate.removeLabel(fromView: self.requestView)
        }else{
            appDelegate.addLabel(toView: self.requestView, text: "No requests")
        }
        
        DispatchQueue.main.async(execute: {
            self.tableView.reloadData()
        })
    }
    
    @IBAction func acceptClicked(_ sender: UIButton) {
        
        let indexPath = NSIndexPath(row: sender.tag, section: 0)
        
        print("accept request of:","\(indexPath.row)")
        
        let user = self.requests[indexPath.row]
        
        //Accepted request and add accepted user under logged-in user's accepted(friend) list
        let acceptRef = dataBaseRef.child(kUserRequests).child(kAccepted).child((FIRAuth.auth()?.currentUser?.uid)!)
        acceptRef.updateChildValues([user.uid!: 1], withCompletionBlock: { (error, ref) in
        
            //Accepted user also update lodded-in user's entry under its accepted(friend) list
            let acceptRef = self.dataBaseRef.child(kUserRequests).child(kAccepted).child(user.uid!)
            acceptRef.updateChildValues([(FIRAuth.auth()?.currentUser?.uid)!: 1])
            
            //Accepted user's request removed from logged-in user's received requests
            let receivedRef = self.dataBaseRef.child(kUserRequests).child(kReceived).child((FIRAuth.auth()?.currentUser?.uid)!).child(user.uid!)
            receivedRef.removeValue(completionBlock: { (error, ref) in
                
                if error != nil {
                    print("Failed to delete request from received:", error as Any)
                    return
                }
                
                showAlert(controller: self, message: "You successfully accepted friend request of \(user.username!).", title: kApplicationName)
                
                if self.requests.count > 0 && self.receivedRequests.count > 0{
                    
                    self.requests.remove(at: indexPath.row)
                    self.receivedRequests.remove(at: indexPath.row)
                    self.tableView.deleteRows(at: [indexPath as IndexPath], with: .right)
                }
                DispatchQueue.main.async(execute: {
                    self.tableView.reloadData()
                })
                
                if self.receivedRequests.count == 0{
                    appDelegate.addLabel(toView: self.requestView, text: "No Requests")
                }
            })
            
            //Logged-in user's request entry removed from Accepted user's sent requests
            let sentRef = self.dataBaseRef.child(kUserRequests).child(kSent).child(user.uid!).child((FIRAuth.auth()?.currentUser?.uid)!)
            sentRef.removeValue(completionBlock: { (error, ref) in
                
                if error != nil {
                    print("Failed to delete request from sent:", error as Any)
                    return
                }
                
                if self.segmentControl.selectedSegmentIndex == 1{
                    if self.sentRequests.count == 0{
                        appDelegate.addLabel(toView: self.requestView, text: "No Requests")
                    }
                }
            })
            
            sentRef.observe(.childRemoved, with: { (snapshot) in
                
                print(snapshot.key)
                
                
                
            }, withCancel: nil)
        })
    }
    
    @IBAction func rejectClicked(_ sender: UIButton) {
        
        let indexPath = NSIndexPath(row: sender.tag, section: 0)
        
        print("reject request of:","\(indexPath.row)")
        
        let user = self.requests[indexPath.row]
        
        //Rejected user's request removed from logged-in user's received requests
        let receivedRef = self.dataBaseRef.child(kUserRequests).child(kReceived).child((FIRAuth.auth()?.currentUser?.uid)!).child(user.uid!)
        receivedRef.removeValue(completionBlock: { (error, ref) in
            
            if error != nil {
                print("Failed to delete request from received:", error as Any)
                return
            }
            
            showAlert(controller: self, message: "You successfully rejected friend request of \(user.username!).", title: kApplicationName)
            
            if self.requests.count > 0 && self.receivedRequests.count > 0{
                
                self.requests.remove(at: indexPath.row)
                self.receivedRequests.remove(at: indexPath.row)
                self.tableView.deleteRows(at: [indexPath as IndexPath], with: .left)
            }
            DispatchQueue.main.async(execute: {
                self.tableView.reloadData()
            })
            
            if self.receivedRequests.count == 0{
                appDelegate.addLabel(toView: self.requestView, text: "No Requests")
            }
        })
        
        //Logged-in user's request entry removed from Rejected user's sent requests
        let sentRef = self.dataBaseRef.child(kUserRequests).child(kSent).child(user.uid!).child((FIRAuth.auth()?.currentUser?.uid)!)
        sentRef.removeValue(completionBlock: { (error, ref) in
            
            if error != nil {
                print("Failed to delete request from sent:", error as Any)
                return
            }
            
            if self.segmentControl.selectedSegmentIndex == 1{
                if self.sentRequests.count == 0{
                    appDelegate.addLabel(toView: self.requestView, text: "No Requests")
                }
            }
        })
        
        sentRef.observe(.childRemoved, with: { (snapshot) in
            
            print(snapshot.key)
            
            
            
        }, withCancel: nil)
    }
    
    @IBAction func logOutAction(_ sender: AnyObject) {
   
        if FIRAuth.auth()!.currentUser != nil {
            do {
                
                //create a reference to the database
                let myConnectionsRef = FIRDatabase.database().reference(withPath: "\(kUsers)/\((FIRAuth.auth()?.currentUser?.uid)!)/\(kConnections)/\(appDelegate.deviceId!))")
                
                //when user logs out, set the value to false
                myConnectionsRef.child(kOnline).setValue(false)
                myConnectionsRef.child(kLastOnline).setValue(NSNumber(value: Int(Date().timeIntervalSince1970)))
                
                try FIRAuth.auth()?.signOut()
                
                let vc = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "Login")
                present(vc, animated: true, completion: nil)
                
            } catch let error as NSError {
                
                showAlert(controller: self, message: error.localizedDescription, title: "😁OOPS😁")
            }
        }
    }
    
    //MARK: - TableView Methods -
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.requests.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let user = self.requests[indexPath.row]
        
        if selectedIndex == 0 {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "receivedRequestCell", for: indexPath) as! UserReceivedRequestCell
            
            cell.usernameLabel.text = user.username
            cell.userCountryLabel.text = user.country
            
            if let profileImageUrl = user.profileImageUrl{
                cell.userImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
            }
            
            cell.acceptButton.addTarget(self, action: #selector(acceptClicked(_:)), for: .touchUpInside)
            cell.acceptButton.tag = indexPath.row
            
            cell.rejectButton.addTarget(self, action: #selector(rejectClicked(_:)), for: .touchUpInside)
            cell.rejectButton.tag = indexPath.row
            
            cell.acceptButton.isExclusiveTouch = true
            cell.rejectButton.isExclusiveTouch = true
            
            return cell
            
        } else {
            
            let cell = tableView.dequeueReusableCell(withIdentifier: "usersCell", for: indexPath) as! UsersTableViewCell
            
            cell.usernameLabel.text = user.username
            cell.userCountryLabel.text = user.country
            
            if let profileImageUrl = user.profileImageUrl{
                cell.userImageView.loadImageUsingCacheWithUrlString(urlString: profileImageUrl)
            }
            
            return cell
        }
    }
}
