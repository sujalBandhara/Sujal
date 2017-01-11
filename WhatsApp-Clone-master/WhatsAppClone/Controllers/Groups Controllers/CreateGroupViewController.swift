//
//  CreateGroupViewController.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit
import Firebase
import Photos

class CreateGroupViewController: UIViewController, UITextFieldDelegate,UIImagePickerControllerDelegate, UINavigationControllerDelegate,UITableViewDataSource,UITableViewDelegate {
    
    @IBOutlet weak var groupImageView: CustomizableImageView!
    @IBOutlet weak var groupnameTextField: UITextField!
    @IBOutlet var tableView: UITableView!
    
    private lazy var groupRef: FIRDatabaseReference = FIRDatabase.database().reference().child(kGroups)
    fileprivate lazy var mediaRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://bypt-chat-app.appspot.com")
    
    private lazy var userRef: FIRDatabaseReference = FIRDatabase.database().reference().child(kUsers)
    
    var users = [User]()
    var selectedUser: [String] = [String]()
    var photoReferenceURL: URL!
    
    var dataBaseRef: FIRDatabaseReference! {
        
        return FIRDatabase.database().reference()
    }
    
    var storageRef: FIRStorage {
        
        return FIRStorage.storage()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        groupnameTextField.delegate = self
        
        self.tableView.allowsMultipleSelection = true
        self.tableView.tableFooterView = UIView(frame: CGRect.zero)
        
        // Creating Tap Gesture to dismiss Keyboard
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(CreateGroupViewController.dismissKeyboard(_:)))
        tapGesture.numberOfTapsRequired = 1
        view.addGestureRecognizer(tapGesture)
        
        // Creating Swipe Gesture to dismiss Keyboard
        let swipDown = UISwipeGestureRecognizer(target: self, action: #selector(CreateGroupViewController.dismissKeyboard(_:)))
        swipDown.direction = .down
        view.addGestureRecognizer(swipDown)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.users = []
        
        self.observeFriends()
    }
    
    //MARK: - Create Action -
    @IBAction func createClicked(sender: AnyObject)
    {
        let data = UIImageJPEGRepresentation(self.groupImageView.image!, 0.8)
        let groupname = self.groupnameTextField.text!
        
        if groupname.isEmpty || data == nil || self.photoReferenceURL == nil {
            
            self.view.endEditing(true)
            
            showAlert(controller: self, message: "it seems like one of the Fields is empty. Please fill all the Fields and Try Again later.", title: "😁OOPS😁")
        }
        else if selectedUser.count <= 1 {
            
            self.view.endEditing(true)
            
            showAlert(controller: self, message: "Please atleast add more two people to make this a group.", title: "😁OOPS😁")
        }
        else {
            self.view.endEditing(true)
            
            //Added Creator Id
            selectedUser.append((FIRAuth.auth()?.currentUser?.uid)!)
            
            let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
            
            self.createGroup(groupName: groupname, creatorName: (FIRAuth.auth()?.currentUser?.displayName)!, creatorId: (FIRAuth.auth()?.currentUser?.uid)!, createdDate: timestamp, data: data!, membersCount: NSNumber(integerLiteral: selectedUser.count), groupMembers: self.selectedUser)
        }
    }
    
    //MARK: - Functions -
    
    func observeFriends() {
        
        appDelegate.addLabel(toView: self.tableView, text: "You don't have any friends yet...")
        
        let friendsRef = dataBaseRef.child(kUserRequests).child(kAccepted).child((FIRAuth.auth()?.currentUser?.uid)!)
        friendsRef.observe(.childAdded, with: { (snapshot) in
            
            if snapshot.exists(){
                
                let userId = snapshot.key
                let userRef = self.dataBaseRef.child(kUsers).child(userId)
                
                userRef.observeSingleEvent(of: .value, with: { (usersnap) in
                    
                    if usersnap.exists(){
                        
                        appDelegate.removeLabel(fromView: self.tableView)
                        
                        let newUser = User(snapshot: usersnap)
                        
                        if newUser.uid != FIRAuth.auth()?.currentUser?.uid{
                            self.users.append(newUser)
                        }
                        
                        DispatchQueue.main.async {
                            self.users.sort(by: { (user1, user2) -> Bool in
                                user1.username!.lowercased() < user2.username!.lowercased()
                            })
                            self.tableView.reloadData()
                        }
                    }
                })
            }
            
        }) { (error) in
            showAlert(controller: self, message: error.localizedDescription, title: "😬OOPS😬")
        }
    }
    
    func createGroup(groupName: String, creatorName: String, creatorId: String, createdDate: NSNumber, data: Data, membersCount: NSNumber, groupMembers: [String]) {
        
        let groupref = groupRef.childByAutoId()
        
        let group = [kGroupName: groupName as AnyObject, kCreatorName: creatorName as AnyObject, kCreatoId: creatorId as AnyObject, kCreatedDate: createdDate, kMembersCount: membersCount] as [String:AnyObject]//Group(groupName: groupName, creatorName: creatorName, creatorId: creatorId, createdDate: createdDate, membersCount: membersCount)
        
        groupref.setValue(group) { (error, ref) in
            
            if error == nil {
                print("Group Created")
                
                //Add groupId under created group
                self.groupRef.child(ref.key).updateChildValues([kGroupId: ref.key])
                
                //Upload Image to Firebase Storage
                self.uploadGroupImageToFirebaseStorage(data: data, key: ref.key)
                
                //Add Members under created group in Firebase Database
                self.addMembersToGroup(members: groupMembers, key: ref.key)
                
            }
            else {
                showAlert(controller: self, message: error!.localizedDescription, title: "😬OOPS😬")
            }
        }
    }
    
    func uploadGroupImageToFirebaseStorage(data: Data, key: String) {
        
        let imagePath = "\(kGroupProfileImages)/\(key).jpg"
        
        let metadata = FIRStorageMetadata()
        metadata.contentType = "image/jpeg"
        
        self.mediaRef.child(imagePath).put(data, metadata: metadata) { (metadata, error) in
            if error == nil {
                
                if metadata!.downloadURL() != nil {
                    
                    //Set groupImageUrl under created group in Firebase Database
                    self.setImageURL(self.mediaRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                }
            }
            else {
                print("Error uploading photo: \(error?.localizedDescription)")
                return
            }
        }
        
        /*self.mediaRef.child(imagePath).putFile(imageFileURL!, metadata: nil) { (metadata, error) in
            if let error = error {
                print(error.localizedDescription)
            }
        }*/
    }
    
    func addMembersToGroup(members: [String], key: String) {
        
        groupRef.child(key).child("groupMembers").setValue(self.selectedUser) { (error, ref) in
            if error == nil {
                print("Members Added")
                
                if appDelegate.userInfo[kGroupIds] == nil {
                    
                    let array: NSMutableArray = NSMutableArray()
                    array.add(key)
                    appDelegate.userInfo[kGroupIds] = array
                }
                else {
                    
                    var tempArray: NSMutableArray = NSMutableArray()
                    tempArray = appDelegate.userInfo[kGroupIds] as! NSMutableArray
                    tempArray.add(key)
                    appDelegate.userInfo[kGroupIds] = tempArray
                }
                
                //Add groupId under every member's GroupIds
                for member in 0..<self.selectedUser.count {
                    
                    let groupIdsRef = self.userRef.child(self.selectedUser[member] as String).child(kGroupIds)
                    
                    groupIdsRef.observeSingleEvent(of: .value, with: { (snapshot) in
                        
                        var array: NSMutableArray = NSMutableArray()
                        
                        if snapshot.exists() {
                            
                            array = snapshot.value as! NSMutableArray
                        }
                        
                        array.add(key)
                        
                        appDelegate.userInfo[kGroupIds] = array
                        
                        groupIdsRef.setValue(array)
                        
                    })
                    /*groupIdsRef.observe(.value, with: {(snapshot) in
                     
                     print(snapshot)
                     
                     var array: NSMutableArray = NSMutableArray()
                     
                     if snapshot.exists() {
                     
                     array = snapshot.value as! NSMutableArray
                     }
                     
                     if !array.contains(groupKey){
                     
                     array.add(groupKey)
                     
                     appDelegate.userInfo["groupIds"] = array
                     
                     groupIdsRef.setValue(array)
                     }
                     })*/
                }
                
                let object = self.selectedUser.index(of: (FIRAuth.auth()?.currentUser?.uid)! as String)
                
                self.selectedUser.remove(at: object!)
                
                self.navigationController?.popViewController(animated: true)
            }
        }
    }
    
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {
        let itemRef = groupRef.child(key)
        itemRef.updateChildValues([kGroupImageUrl: url])
    }
    
    //MARK: - TableView -
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // #warning Incomplete implementation, return the number of rows
        return users.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 70
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "usersCell", for: indexPath) as! UsersTableViewCell
        
        let user =  users[(indexPath as NSIndexPath).row]
        
        // Configure the cell...
        cell.usernameLabel.text = user.username
        cell.userCountryLabel.text = user.country
        
        if user.profileImageUrl != nil
        {
            cell.userImageView.loadImageUsingCacheWithUrlString(urlString: user.profileImageUrl!)
        }
        
        /*storageRef.reference(forURL: users[(indexPath as NSIndexPath).row].photoUrl!).data(withMaxSize: 1*1024*1024) { (data, error) in
         if error == nil {
         
         DispatchQueue.main.async(execute: {
         if let data = data {
         
         cell.userImageView.image = UIImage(data: data)
         }
         })
         
         
         }else {
         
         /*let alertView = SCLAlertView()
         alertView.showError("😁OOPS😁", subTitle: error!.localizedDescription)*/
         
         }
         }*/
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        print("\(indexPath.row)")
        
        selectedUser.append(users[indexPath.row].uid!)
    }
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        
        print("\(indexPath.row)")
        
        let object = selectedUser.index(of: users[indexPath.row].uid!)
        selectedUser.remove(at: object!)
    }
    
    //MARK: - ImagePicker -
    // Choosing User Picture
    @IBAction func choosePictureAction(_ sender: AnyObject) {
        selectedUser.removeAll()
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        
        let alertController = UIAlertController(title: "Add a Picture", message: "Choose From", preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (action) in
            pickerController.sourceType = .camera
            self.present(pickerController, animated: true, completion: nil)
        }
        
        let photosLibraryAction = UIAlertAction(title: "Photos Library", style: .default) { (action) in
            pickerController.sourceType = .photoLibrary
            self.present(pickerController, animated: true, completion: nil)
        }
        
        let savedPhotosAction = UIAlertAction(title: "Saved Photos Album", style: .default) { (action) in
            pickerController.sourceType = .savedPhotosAlbum
            self.present(pickerController, animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        
        alertController.addAction(cameraAction)
        alertController.addAction(photosLibraryAction)
        alertController.addAction(savedPhotosAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingImage image: UIImage, editingInfo: [String : AnyObject]?) {
        self.dismiss(animated: true, completion: nil)
        
        self.groupImageView.image = image
        
        // 1
        photoReferenceURL = editingInfo?[UIImagePickerControllerReferenceURL] as? URL
    }
    
    //MARK: - TextField -
    // Dismissing all editing actions when User Tap or Swipe down on the Main View
    func dismissKeyboard(_ gesture: UIGestureRecognizer){
        self.view.endEditing(true)
    }
    
    // Dismissing the Keyboard with the Return Keyboard Button
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        groupnameTextField.resignFirstResponder()
        return true
    }
    // Moving the View up after the Keyboard appears
    func textFieldDidBeginEditing(_ textField: UITextField) {
        //animateView(true, moveValue: 80)
    }
    // Moving the View down after the Keyboard disappears
    func textFieldDidEndEditing(_ textField: UITextField) {
        //animateView(false, moveValue: 80)
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
}
