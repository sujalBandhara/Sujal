//
//  ChatViewController.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import UIKit
import JSQMessagesViewController
import FirebaseAuth
import FirebaseDatabase
import FirebaseStorage
import Photos
import MobileCoreServices
import AVFoundation
import AVKit

extension UIImageView: DisplaceableView {}

class ChatViewController: JSQMessagesViewController, GalleryItemsDatasource, GalleryDisplacedViewsDatasource {

    //MARK: - User-defined Variables -
    var receiverId: String!
    var receiverDisplayName: String!
    var receiverIds: [String]!
    var groupKey: String!
    var adminId: String?
    var users = [User]()
    
    var isFromFriend: Bool!
    
    var imageViews: [UIImageView] = []
    
    //MARK: - Properties -
    private let imageURLNotSetKey = "NOTSET"
    
    private lazy var channelRef: FIRDatabaseReference = FIRDatabase.database().reference()
    private var channelRefHandle: FIRDatabaseHandle?
    
    //private lazy var userIsTypingRef: FIRDatabaseReference = self.channelRef.child("typingIndicator").child(self.senderId) // 1
    
    //private var localTyping = false // 2
    
    /*var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            // 3
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }*/
    
    //private lazy var usersTypingQuery: FIRDatabaseQuery = self.channelRef.child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    ///
    
//    var databaseRef: FIRDatabaseReference! {
//        
//        return FIRDatabase.database().reference()
//    }
    var storageRefe: FIRStorage {
        
        return FIRStorage.storage()
    }
    
    private lazy var messageRef: FIRDatabaseReference = FIRDatabase.database().reference().child(kChatRooms).child(kMessages)
    fileprivate lazy var storageRef: FIRStorageReference = FIRStorage.storage().reference(forURL: "gs://bypt-chat-app.appspot.com")
    private lazy var userIsTypingRef: FIRDatabaseReference = FIRDatabase.database().reference().child(kChatRooms).child("typingIndicator").child(self.senderId)
    private lazy var usersTypingQuery: FIRDatabaseQuery = FIRDatabase.database().reference().child(kChatRooms).child("typingIndicator").queryOrderedByValue().queryEqual(toValue: true)
    
    private lazy var groupRef: FIRDatabaseReference = FIRDatabase.database().reference().child(kGroups)
    private lazy var userRef: FIRDatabaseReference = FIRDatabase.database().reference().child(kUsers)
    
    private var newMessageRefHandle: FIRDatabaseHandle?
    private var updatedMessageRefHandle: FIRDatabaseHandle?
    
    private var messages: [JSQMessage] = []
    private var tempMsgs: [Message] = []
    private var photoMessageMap = [String: JSQPhotoMediaItem]()
    private var videoMessageMap = [String: JSQVideoMediaItem]()
    
    private var localTyping = false
    
    var isTyping: Bool {
        get {
            return localTyping
        }
        set {
            localTyping = newValue
            userIsTypingRef.setValue(newValue)
        }
    }
    /*var channel: Channel? {
        didSet {
            title = channel?.name
        }
    }*/
    
    var outgoingBubbleImageView: JSQMessagesBubbleImage!
    var incomingBubbleImageView: JSQMessagesBubbleImage!

    //MARK: - View Life Cycle -
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.navigationItem.title = self.receiverDisplayName!
        
        let factory = JSQMessagesBubbleImageFactory()
        
        incomingBubbleImageView = factory?.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
        outgoingBubbleImageView = factory?.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
        
        //remove all data from tempMsgs
        tempMsgs = []
        
        //Set Messages
        observeMessages()
        
        self.collectionView.allowsSelection = true
        
        //collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize.zero
        //collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize.zero
        
        if isFromFriend == false {
            let button1 = UIBarButtonItem(image: UIImage(named: "info_icon"), style: .plain, target: self, action: #selector(ChatViewController.action))
            self.navigationItem.rightBarButtonItem  = button1
            
            observeMembers()
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
      
        observeTyping()
    }
    
    //MARK: - observer Group Members -
    private func observeMembers() {
        
        let groupRef = self.groupRef.child(receiverId).child("groupMembers")
        
        groupRef.observe(.value, with: {(memberSnap) in
            
            if memberSnap.exists() {
                
                let memberIds = memberSnap.value as! NSMutableArray
                
                var allUsers = [User]()
                
                for i in 0..<memberIds.count{
                    
                    self.userRef.child(memberIds[i] as! String).observe(.value, with: { (snapshot) in
                        
                        let myself = User(snapshot: snapshot)
                        
                        allUsers.append(myself)
                        
                        self.users = allUsers
                        
                    }) { (error) in
                        
                        let alertView = SCLAlertView()
                        _ = alertView.showError("😁OOPS😁", subTitle: error.localizedDescription)
                    }
                }
            }
        })
    }
    
    //MARK: - Observe Messages -
    private func observeMessages() {
        
        let uid = FIRAuth.auth()?.currentUser?.uid
        let toId = receiverId
        
        /*guard let uid = FIRAuth.auth()?.currentUser?.uid, let toId = receiverId else {
         return
         }*/
        
        // 1.
        let messageQuery: FIRDatabaseQuery
        let userMessagesRef: FIRDatabaseReference
        
        userMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(uid!).child(toId!)
        messageQuery = userMessagesRef.queryLimited(toLast:25)
        
        // 2. We can use the observe method to listen for new
        // messages being written to the Firebase DB
        userMessagesRef.observe(.childAdded, with: { (snapshot) in
            
            let messageId = snapshot.key
            
            let messagesRef = FIRDatabase.database().reference().child(kChatRooms).child(kMessages).child(messageId)
            
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                if snapshot.exists() {
                    
                    let messageData = snapshot.value as! NSMutableDictionary
                    
                    let tempMsg = Message(snapshot: snapshot)
                    self.tempMsgs.append(tempMsg)
                    
                    if let id = messageData[kFromId] as! String!, let receiverId = messageData[kToId] as! String!, let timestamp = messageData[kTimestamp] as! NSNumber!, let text = messageData[kText] as! String!, text.characters.count > 0 {
                        
                        //if (id == uid && receiverId == toId) || (id == toId && receiverId == uid) {
                        
                        let timestampDate = NSDate(timeIntervalSince1970: Double(timestamp))
                        
                        self.addMessage(id, displayName: (FIRAuth.auth()?.currentUser?.displayName)!, date: timestampDate as Date, text: text)
                        
                        self.finishReceivingMessage()
                        
                        self.collectionView.reloadData()
                        //}
                    }
                    else if let id = messageData[kFromId] as! String!, let receiverId = messageData[kToId] as! String!, let timestamp = messageData[kTimestamp] as! NSNumber!, let imageUrl = messageData[kImageUrl] as! String!, (messageData[kImageUrl] as! String!) != "" {
                        
                        //if (id == uid && receiverId == toId) || (id == toId && receiverId == uid) {
                        
                        let timestampDate = NSDate(timeIntervalSince1970: Double(timestamp))
                        
                        if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                            self.addPhotoMessage(id, displayName: "", date: timestampDate as Date, key: snapshot.key, mediaItem: mediaItem)
                            
                            if imageUrl.hasPrefix("gs://") {
                                self.fetchImageDataAtURL(imageUrl, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                            }
                        }
                        //}
                    }
                    else if let id = messageData[kFromId] as! String!, let receiverId = messageData[kToId] as! String!, let timestamp = messageData[kTimestamp] as! NSNumber!, let videoUrl = messageData[kVideoUrl] as! String! {
                        
                        //if (id == uid && receiverId == toId) || (id == toId && receiverId == uid) {
                        
                        let timestampDate = NSDate(timeIntervalSince1970: Double(timestamp))
                        
                        if let mediaItem = JSQVideoMediaItem(maskAsOutgoing: id == self.senderId) {
                            self.addVideoMessage(id, displayName: "", date: timestampDate as Date, key: snapshot.key, mediaItem: mediaItem)
                            
                            self.fetchVideoDataAtURL(videoUrl, forMediaItem: mediaItem, clearsVideoMessageMapOnSuccessForKey: nil)
                            
                            /*if videoUrl.hasPrefix("gs://") {
                             self.fetchImageDataAtURL(videoUrl, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: nil)
                             }*/
                        }
                        //}
                    }
                }
            }){ (error) in
                
                print("Error:", error.localizedDescription)
            }
            //}
        }) { (error) in
            showAlert(controller: self, message: error.localizedDescription, title: "😁OOPS😁")
        }
        
        // We can also use the observer method to listen for
        // changes to existing messages.
        // We use this to be notified when a photo has been stored
        // to the Firebase Storage, so we can update the message data
        //if self.isFromFriend == true {
        
        messageRef.observe(.childChanged, with: { (snapshot) in
            
            let messageId = snapshot.key
            let messagesRef = FIRDatabase.database().reference().child(kChatRooms).child(kMessages).child(messageId)
            
            //let key = snapshot.key
            //let messageData = snapshot.value as! Dictionary<String, String>
            
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                
                let messageData = snapshot.value as! NSMutableDictionary
                
                if let id = messageData[kFromId] as! String!, let receiverId = messageData[kToId] as! String!, let timestamp = messageData[kTimestamp] as! NSNumber!, let text = messageData[kText] as! String!, text.characters.count > 0 {
                    
                    if (id == (FIRAuth.auth()?.currentUser?.uid)! && receiverId == self.receiverId) || (id == self.receiverId && receiverId == (FIRAuth.auth()?.currentUser?.uid)!) {
                        
                        /*let timestampDate = NSDate(timeIntervalSince1970: Double(timestamp)!)
                         
                         // 4
                         //self.addMessage(id, displayName: "", text: text)
                         let message = Message(senderId: id, receiverId: receiverId, timestamp: timestamp, text: text, key: key)
                         
                         let jqMsg = JSQMessage(senderId: id, senderDisplayName: "", date: timestampDate as Date, text: text)
                         
                         //let index1 = self.messages.index(of: jqMsg!)
                         //print(index1)
                         //self.messages.insert(JSQMessage(senderId:id, displayName: "", text: text), at: 18)
                         
                         self.messageRef.child(key).setValue(message.toAnyObjectT()) { (error, ref) in
                         if error == nil {
                         JSQSystemSoundPlayer.jsq_playMessageSentSound()
                         //5
                         self.finishSendingMessage()
                         
                         self.collectionView.reloadData()
                         }else {
                         
                         }
                         }*/
                    }
                    
                    /*for messages in snapshot.children {
                     
                     let messages = snapshot.childSnapshot(forPath: "Messages")
                     
                     var dict: NSMutableDictionary = NSMutableDictionary()
                     dict = messages.value as! NSMutableDictionary
                     print(dict)
                     }*/
                }
                else if let imageUrl = messageData[kImageUrl] as! String! {
                    // The photo has been updated.
                    if let mediaItem = self.photoMessageMap[messageId] {
                        self.fetchImageDataAtURL(imageUrl, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: messageId)
                    }
                }
                else if let videoUrl = messageData[kVideoUrl] as! String! {
                    // The video has been updated.
                    if let mediaItem = self.videoMessageMap[messageId] {
                        self.fetchVideoDataAtURL(videoUrl, forMediaItem: mediaItem, clearsVideoMessageMapOnSuccessForKey: messageId)
                    }
                }
            })
        }){ (error) in
            showAlert(controller: self, message: error.localizedDescription, title: "😁OOPS😁")
        }
        
        userMessagesRef.observe(.childRemoved, with: { (snapshot) in
            print(snapshot.key)
            
            self.messageRef.child(snapshot.key).observe(.value, with: { (messageSnap) in
                print(messageSnap.key)
                
                let snap = Message(snapshot: messageSnap)
                
                var indexToRemove = Int()
                
                if let id = snap.fromId, let timestamp = snap.timestamp, let text = snap.text, text.characters.count > 0 {
                    
                    let timestamp = timestamp
                    let timestampDate = NSDate(timeIntervalSince1970: Double(timestamp))
                    
                    let message = JSQMessage(senderId: id, senderDisplayName: (FIRAuth.auth()?.currentUser?.displayName)!, date: timestampDate as Date!, text: text)
                    
                    indexToRemove = self.messages.index(of: message!)!
                }
                else if let id = snap.fromId, let timestamp = snap.timestamp, let imageUrl = snap.imageUrl, imageUrl != "" {
                    
                    let timestamp = timestamp
                    let timestampDate = NSDate(timeIntervalSince1970: Double(timestamp))
                    
                    if self.messages[0].value(forKey: "date") as! Date ==  timestampDate as Date{
                        indexToRemove = 0
                    }
                    /*if let mediaItem = JSQPhotoMediaItem(maskAsOutgoing: id == self.senderId) {
                        
                        let message = JSQMessage(senderId: id, senderDisplayName: (FIRAuth.auth()?.currentUser?.displayName)!, date: timestampDate as Date!, media: mediaItem)
                        
                        //let datePredicate = NSPredicate(format: "date > %@", timestampDate as NSDate)
                        
                        self.messages.index(after: datePredicate)
                        
                        if (mediaItem.image == nil) {
                            self.photoMessageMap[messageSnap.key] = mediaItem
                        }
                        indexToRemove = self.messages.index(of: message!)!
                    }*/
                }
                else if let id = snap.fromId, let timestamp = snap.timestamp, let videoUrl = snap.videoUrl, videoUrl != "" {
                    
                    let timestamp = timestamp
                    let timestampDate = NSDate(timeIntervalSince1970: Double(timestamp))
                    
                    if self.messages[0].value(forKey: "date") as! Date ==  timestampDate as Date{
                        indexToRemove = 0
                    }
                    
                    /*if let mediaItem = JSQVideoMediaItem(maskAsOutgoing: id == self.senderId) {
                        
                        let message = JSQMessage(senderId: id, senderDisplayName: (FIRAuth.auth()?.currentUser?.displayName)!, date: timestampDate as Date!, media: mediaItem)
                        
                        indexToRemove = self.messages.index(of: message!)!
                    }*/
                }
                
                print("\(indexToRemove)")
                self.messages.remove(at: indexToRemove)
                
                self.collectionView.reloadData()
            })
        })
    }
    
    private func observeTyping() {
        let typingIndicatorRef = FIRDatabase.database().reference().child(kChatRooms).child("typingIndicator")
        userIsTypingRef = typingIndicatorRef.child(receiverId)//senderId
        userIsTypingRef.onDisconnectRemoveValue()
        
        // 1
        usersTypingQuery.observe(.value) { (data: FIRDataSnapshot) in
            // 2 You're the only one typing, don't show the indicator
            if data.childrenCount == 1 && self.isTyping {
                return
            }
            
            // 3 Are there others typing?
            self.showTypingIndicator = data.childrenCount > 0
            self.scrollToBottom(animated: true)
        }
    }
    
    func addMessage(_ id: String, displayName: String, date: Date, text: String){
        
        let message = JSQMessage(senderId: id, senderDisplayName: displayName, date: date, text: text)//JSQMessage(senderId:id, displayName: displayName, text: text)
        messages.append(message!)
    }
    
    func addPhotoMessage(_ id: String, displayName: String, date: Date, key: String, mediaItem: JSQPhotoMediaItem) {
    
        if let message = JSQMessage(senderId: id, senderDisplayName: displayName, date: date, media: mediaItem) {
            messages.append(message)
            
            if (mediaItem.image == nil) {
                photoMessageMap[key] = mediaItem
            }
            
            collectionView.reloadData()
        }
    }
    
    func addVideoMessage(_ id: String, displayName: String, date: Date, key: String, mediaItem: JSQVideoMediaItem) {
        
        if let message = JSQMessage(senderId: id, senderDisplayName: displayName, date: date, media: mediaItem) {
            messages.append(message)
            
            if (mediaItem.fileURL == nil) {
                videoMessageMap[key] = mediaItem
            }
            
            collectionView.reloadData()
        }
    }
    
    func fetchImageDataAtURL(_ photoURL: String, forMediaItem mediaItem: JSQPhotoMediaItem, clearsPhotoMessageMapOnSuccessForKey key: String?) {
        let storageRef = FIRStorage.storage().reference(forURL: photoURL)
        storageRef.data(withMaxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            storageRef.metadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
                
                if (metadata?.contentType == "image/gif") {
                    mediaItem.image = UIImage.gifWithData(data!)
                } else {
                    mediaItem.image = UIImage.init(data: data!)
                }
                
                self.collectionView.reloadData()
                
                guard key != nil else {
                    return
                }
                self.photoMessageMap.removeValue(forKey: key!)
            })
        }
    }
    
    func fetchVideoDataAtURL(_ videoURL: String, forMediaItem mediaItem: JSQVideoMediaItem, clearsVideoMessageMapOnSuccessForKey key: String?) {
        let storageRef = FIRStorage.storage().reference(forURL: videoURL)
        storageRef.data(withMaxSize: INT64_MAX){ (data, error) in
            if let error = error {
                print("Error downloading image data: \(error)")
                return
            }
            
            storageRef.metadata(completion: { (metadata, metadataErr) in
                if let error = metadataErr {
                    print("Error downloading metadata: \(error)")
                    return
                }
                
                if (metadata?.contentType == "video/quicktime") {
                    if let downloadVideoUrl = metadata?.downloadURL() {
                        mediaItem.fileURL = downloadVideoUrl
                        mediaItem.isReadyToPlay = true
                    }
                }
                
                self.collectionView.reloadData()
                
                guard key != nil else {
                    return
                }
                self.videoMessageMap.removeValue(forKey: key!)
            })
        }
    }
    
    func sendTextMessage(message: [String:AnyObject]) {
        
        let messageRef = self.messageRef.childByAutoId()
            
            messageRef.setValue(message){ (error,ref) in
                if error == nil {
                    JSQSystemSoundPlayer.jsq_playMessageSentSound()
                    self.finishSendingMessage()
                    
                    if self.isFromFriend == true{
                        
                        let userMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(self.senderId).child(self.receiverId)
                        
                        let messageId = messageRef.key
                        userMessagesRef.updateChildValues([messageId: 1])
                        
                        let recipientUserMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(self.receiverId).child(self.senderId)
                        recipientUserMessagesRef.updateChildValues([messageId: 1])
                        
                    } else {
                        for index in 0..<self.receiverIds.count{
                            
                            let userMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(self.receiverIds[index]).child(self.receiverId)
                            
                            let messageId = messageRef.key
                            userMessagesRef.updateChildValues([messageId: 1])
                            
                            //let recipientUserMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(self.receiverId).child(self.senderId)
                            //recipientUserMessagesRef.updateChildValues([messageId: 1])
                        }
                    }
                    
                }else {
                    print("error:", error?.localizedDescription ?? "")
                    return
                }
            }
    }
    
    func sendPhotoMessage(image: UIImage) -> String? {
        
        var itemRef = FIRDatabaseReference()
        
        let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
        
        //if isFromFriend == true {
        
        itemRef = messageRef.childByAutoId()
        
        var message = [String: AnyObject]()
        
        if self.isFromFriend == true {
            
            message = [kFromId: senderId as AnyObject, kToId: receiverId as AnyObject, kTimestamp: timestamp, kImageUrl: imageURLNotSetKey as AnyObject, kImageWidth: NSNumber(value: Double(image.size.width)), kImageHeight: NSNumber(value: Double(image.size.height)), kGroupMessage: kNO as AnyObject]
        } else {
            
            message = [kFromId: senderId as AnyObject, kToId: receiverId as AnyObject, kTimestamp: timestamp, kImageUrl: imageURLNotSetKey as AnyObject, kImageWidth: NSNumber(value: Double(image.size.width)), kImageHeight: NSNumber(value: Double(image.size.height)), kGroupMessage: kYES as AnyObject]
        }
        
        itemRef.setValue(message){ (error,ref) in
            if error == nil {
                
                if self.isFromFriend == true{
                    
                    let userMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(self.senderId).child(self.receiverId)
                    
                    let messageId = ref.key
                    userMessagesRef.updateChildValues([messageId: 1])
                    
                    let recipientUserMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(self.receiverId).child(self.senderId)
                    recipientUserMessagesRef.updateChildValues([messageId: 1])
                    
                } else {
                    for index in 0..<self.receiverIds.count{
                        
                        let userMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(self.receiverIds[index]).child(self.receiverId)
                        
                        let messageId = ref.key
                        userMessagesRef.updateChildValues([messageId: 1])
                        
                        //let recipientUserMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(self.receiverId).child(self.senderId)
                        //recipientUserMessagesRef.updateChildValues([messageId: 1])
                    }
                }
                
            }else {
                print("error:", error?.localizedDescription ?? "")
                return
            }
        }
        /*}
         else {
         
         itemRef = groupRef.child(groupKey).child(kMessages).childByAutoId()
         
         let message = [
         kFromId: senderId as AnyObject,
         kSenderName: senderDisplayName as AnyObject,
         kTimestamp: timestamp,
         kImageUrl: imageURLNotSetKey as AnyObject,
         kImageWidth: NSNumber(value: Double(image.size.width)),
         kImageHeight: NSNumber(value: Double(image.size.height))
         ] as [String:AnyObject]
         
         itemRef.setValue(message)
         }*/
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        
        return itemRef.key
    }
    
    func sendVideoMessage(info: [String:AnyObject]) -> String? {
        
        var itemRef = FIRDatabaseReference()
        
        let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
        
        //if isFromFriend == true {
            
            itemRef = messageRef.childByAutoId()
        
            itemRef.setValue(info){ (error,ref) in
                if error == nil {
                    
                    if self.isFromFriend == true{
                        
                        let userMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(self.senderId).child(self.receiverId)
                        
                        let messageId = ref.key
                        userMessagesRef.updateChildValues([messageId: 1])
                        
                        let recipientUserMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(self.receiverId).child(self.senderId)
                        recipientUserMessagesRef.updateChildValues([messageId: 1])
                        
                    } else {
                        for index in 0..<self.receiverIds.count{
                            
                            let userMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(self.receiverIds[index]).child(self.receiverId)
                            
                            let messageId = ref.key
                            userMessagesRef.updateChildValues([messageId: 1])
                            
                            //let recipientUserMessagesRef = FIRDatabase.database().reference().child(kUserMessages).child(self.receiverId).child(self.senderId)
                            //recipientUserMessagesRef.updateChildValues([messageId: 1])
                        }
                    }
                }else {
                    print("error:", error!.localizedDescription)
                    return
                }
            }
        /*}
        else {
            
            itemRef = groupRef.child(groupKey).child(kMessages).childByAutoId()
            
            let messageItem = [
                kVideoUrl: imageURLNotSetKey as AnyObject,
                kFromId: senderId! as AnyObject,
                kSenderName: (FIRAuth.auth()?.currentUser?.displayName)! as AnyObject,
                kTimestamp: timestamp,
                ] as [String:AnyObject]
            
            itemRef.setValue(info)
        }*/
        
        JSQSystemSoundPlayer.jsq_playMessageSentSound()
        
        finishSendingMessage()
        
        return itemRef.key
    }
    
    func setImageURL(_ url: String, forPhotoMessageWithKey key: String) {

        var itemRef = FIRDatabaseReference()
        
        //if isFromFriend == true {
            
            itemRef = messageRef.child(key)
        /*}
        else {
            itemRef = groupRef.child(groupKey).child(kMessages).child(key)
        }*/

        itemRef.updateChildValues([kImageUrl: url])
        
        /*// The photo has been updated.
        if let mediaItem = self.photoMessageMap[key] {
            self.fetchImageDataAtURL(url, forMediaItem: mediaItem, clearsPhotoMessageMapOnSuccessForKey: key)
        }*/
    }
    
    //MARK: - Group Actions -
    @IBAction func action(sender: AnyObject)
    {
        let infoVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "GroupInfoViewController") as? GroupInfoViewController
        infoVC?.users = self.users
        infoVC?.groupName = self.receiverDisplayName
        infoVC?.groupKey = self.receiverId
        infoVC?.adminId = self.adminId
        self.navigationController?.pushViewController(infoVC!, animated: true)
    }
    
    //MARK: - Actions -
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!) {
    
        let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
        
        if isFromFriend == true {
            //One-to-One Chat
            let message = [kFromId:senderId as AnyObject, kToId: receiverId as AnyObject, kTimestamp: timestamp, kText: text as AnyObject, kGroupMessage: kNO as AnyObject] as [String:AnyObject]
            
            self.sendTextMessage(message: message)
        }
        else {
            //Group Chat
            let message = [kFromId:senderId as AnyObject, kToId: receiverId as AnyObject, kTimestamp: timestamp, kText: text as AnyObject, kGroupMessage: kYES as AnyObject] as [String:AnyObject]
            
            self.sendTextMessage(message: message)
        }
        isTyping = false
    }
    
    override func didPressAccessoryButton(_ sender: UIButton) {
        
        let pickerController = UIImagePickerController()
        pickerController.delegate = self
        pickerController.allowsEditing = true
        
        let alertController = UIAlertController(title: "Add a Picture/Video", message: "Choose From", preferredStyle: .actionSheet)
        
        let cameraAction = UIAlertAction(title: "Camera", style: .default) { (action) in
            
            if UIImagePickerController.isSourceTypeAvailable(.camera){
                pickerController.sourceType = .camera
            } else {
                showAlert(controller: self, message: "Device has no camera.", title: "😬OOPS😬")
                return
            }
            
            pickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            self.present(pickerController, animated: true, completion: nil)
        }
        
        let photosLibraryAction = UIAlertAction(title: "Photos Library", style: .default) { (action) in
            pickerController.sourceType = .photoLibrary
            pickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            self.present(pickerController, animated: true, completion: nil)
        }
        
        let savedPhotosAction = UIAlertAction(title: "Saved Photos Album", style: .default) { (action) in
            pickerController.sourceType = .savedPhotosAlbum
            pickerController.mediaTypes = [kUTTypeImage as String, kUTTypeMovie as String]
            self.present(pickerController, animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .destructive, handler: nil)
        
        alertController.addAction(cameraAction)
        alertController.addAction(photosLibraryAction)
        alertController.addAction(savedPhotosAction)
        alertController.addAction(cancelAction)
        
        
        present(alertController, animated: true, completion: nil)
    }
    
    //MARK: - CollectionView -
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = super.collectionView(collectionView, cellForItemAt: indexPath) as! JSQMessagesCollectionViewCell
        
        let message = messages[(indexPath as NSIndexPath).item]
        
        if message.senderId == senderId {
            cell.textView?.textColor = UIColor.white
            cell.cellTopLabel.text = ",n.,m"
            cell.messageBubbleTopLabel.text = "dvfxzg"
        }
        else {
            cell.textView?.textColor = UIColor.black
            cell.cellTopLabel.text = "fgfgg"
            cell.messageBubbleTopLabel.text = "dcx"
        }
        
        if message.isMediaMessage == true {
            
            if tempMsgs[(indexPath as NSIndexPath).item].videoUrl == nil{
                
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(openImage(gestureView:)))
                tapGesture.numberOfTapsRequired = 1
                cell.messageBubbleContainerView.addGestureRecognizer(tapGesture)
                cell.messageBubbleContainerView.tag = indexPath.row
            }
        }
        
        cell.avatarImageView.image = JSQMessagesAvatarImageFactory.circularAvatarHighlightedImage(UIImage(named: "app_icon.png"), withDiameter: 48)
        
        userRef.child(message.senderId).observe(.value, with: { (userSnap) in
            
            let user = userSnap.value as! NSMutableDictionary
            
            if let photoUrl = user[kProfileImageUrl] {

                cell.avatarImageView.loadImageUsingCacheWithUrlString(urlString: photoUrl as! String)
//                self.storageRefe.reference(forURL: photoUrl as! String).data(withMaxSize: 1*1024*1024*1024) { (data, error) in
//                    if error == nil {
//                        
//                        DispatchQueue.main.async(execute: {
//                            if let data = data {
//                                
//                                cell.avatarImageView.image = JSQMessagesAvatarImageFactory.circularAvatarImage(UIImage(data: data), withDiameter: 48)
//                            }
//                        })
//                    } else {
//                        
//                        let alertView = SCLAlertView()
//                        alertView.showError("😁OOPS😁", subTitle: error!.localizedDescription)
//                    }
//                }
            }
        })
        return cell
    }
    
    var player: AVPlayer?
    var playerLayer: AVPlayerLayer?
    
    @IBAction func handlePlay(sender: AnyObject) {
        
        let indexPath = NSIndexPath(item: sender.tag, section: 0)
        
        let cell = self.collectionView(collectionView, cellForItemAt: (indexPath as IndexPath)) as! JSQMessagesCollectionViewCell
        
        if let videoUrlString = tempMsgs[(indexPath as NSIndexPath).item].videoUrl {
            
            let str = "https://firebasestorage.googleapis.com/v0/b/bypt-chat-app.appspot.com/o/6cJ6YFUA7jNIWXH4Kkd5hXEUN5F3%2F502111043125%2Fmovie.mov?alt=media&token=14af0b55-5409-4dd6-b2bf-11e404f05c7a"
            
            //player = AVPlayer(url: URL(fileURLWithPath: videoUrlString))
            //let videoStr = videoUrlString.addingPercentEscapes(using: String.Encoding.utf8)
            let fileurl = Foundation.URL(fileURLWithPath: str)
            player = AVPlayer(url: fileurl.absoluteURL)
            playerLayer = AVPlayerLayer(player: player)
            playerLayer?.frame = cell.bounds
            cell.layer.addSublayer(playerLayer!)
            
            player?.play()
            
            print("play video...")
        }
        
    }
    
    func tapped(_ recognizer: UITapGestureRecognizer) {
        if recognizer.state == UIGestureRecognizerState.ended {
            let tapLocation = recognizer.location(in: self.collectionView)
            if let tapIndexPath = self.collectionView.indexPathForItem(at: tapLocation) {
                if let tappedCell = self.collectionView.cellForItem(at: tapIndexPath) as? JSQMessagesCollectionViewCell {
                    //do what you want to cell here
                    print(tappedCell)
                }
            }
        }
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource! {
        
        let message = messages[indexPath.item]
        if message.senderId == senderId {
            return outgoingBubbleImageView
        }else {
            return incomingBubbleImageView
        }
        
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource! {
        return nil
    }
    
    func openImage(gestureView: UITapGestureRecognizer)
    {
        if let mapView = gestureView.view
        {
            if let displacedView = (mapView.subviews[0] as? UIImageView){
                
                if displacedView.image == nil {
                    return
                }
                
                imageViews.removeAll()
                
                imageViews.append(displacedView)
                
                guard let displacedViewIndex = imageViews.index(of: displacedView) else { return }
                
                let frame = CGRect(x: 0, y: 0, width: 200, height: 24)
                let headerView = CounterView(frame: frame, currentIndex: displacedViewIndex, count: imageViews.count)
                let footerView = CounterView(frame: frame, currentIndex: displacedViewIndex, count: imageViews.count)
                
                let galleryViewController = GalleryViewController(startIndex: displacedViewIndex, itemsDatasource: self, displacedViewsDatasource: self, configuration: galleryConfiguration())
                //galleryViewController.headerView = headerView
                //galleryViewController.footerView = footerView
                
                galleryViewController.launchedCompletion = {
                    print("LAUNCHED")
                }
                galleryViewController.closedCompletion = { print("CLOSED")
                }
                galleryViewController.swipedToDismissCompletion = { print("SWIPE-DISMISSED")
                }
                galleryViewController.landedPageAtIndexCompletion = { index in
                    
                    print("LANDED AT INDEX: \(index)")
                    
                    headerView.currentIndex = index
                    footerView.currentIndex = index
                }
                
                self.presentImageGallery(galleryViewController)
            }
        }
    }

    
    //MARK: - TextView -
    override func textViewDidChange(_ textView: UITextView) {
        super.textViewDidChange(textView)
        // If the text is not empty, the user is typing
        
        isTyping = textView.text != ""
    }
    
    //MARK: - Upload Media to Firebase -
    func uploadImageToFirebase(_ info: [String:Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        } else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            
            if let uploadData = UIImageJPEGRepresentation(selectedImage, 0.5) {
                
                if let key = sendPhotoMessage(image: selectedImage) {
                    
                    var storagePath = String()
                    
                    if self.isFromFriend == true {
                        
                        storagePath = "\(kUserMessagesImages)/\((FIRAuth.auth()?.currentUser?.uid)!)/\(Int64(Date.timeIntervalSinceReferenceDate * 1000))/\("image.jpg")"
                    }
                    else {
                        
                        storagePath = "\(kGroupMessagesImages)/\((self.receiverId)!)/\(Int64(Date.timeIntervalSinceReferenceDate * 1000))/\("image.jpg")"
                    }
                    
                    let metadata = FIRStorageMetadata()
                    metadata.contentType = "image/jpeg"
                    
                    //put image on Firebase storage
                    self.storageRef.child(storagePath).put(uploadData, metadata: metadata){ (metadata, error) in
                        if let error = error {
                            print("Error uploading photo: \(error.localizedDescription)")
                            return
                        }
                        //update
                        self.setImageURL(self.storageRef.child((metadata?.path)!).description, forPhotoMessageWithKey: key)
                    }
                }
            }
        }
    }
    
    func uploadVideoToFirebase(_ url: URL) {
        
        var fileName = String()
        
        if self.isFromFriend == true {
             fileName = "\(kUserMessagesVideos)/\((FIRAuth.auth()?.currentUser?.uid)!)/\(Int64(Date.timeIntervalSinceReferenceDate * 1000))/\("movie.mov")"
        }
        else {
            
            fileName = "\(kGroupMessagesVideos)/\((self.receiverId)!)/\(Int64(Date.timeIntervalSinceReferenceDate * 1000))/\("movie.mov")"
        }
        
        let uploadtask = self.storageRef.child(fileName).putFile(url, metadata: nil, completion: { (metadata, error) in
            
            if let error = error{
                print("Error uploading photo: \(error.localizedDescription)")
                return
            }
            
            if let videoUrl = metadata?.downloadURL()?.absoluteString {
                print(videoUrl)
                
                if let thumbnailImage = self.thumbnailImageForFileUrl(fileUrl: url) {
                    
                    let timestamp = NSNumber(value: Int(Date().timeIntervalSince1970))
                    
                    let messageData: [String: AnyObject]
                    
                    if self.isFromFriend == true{
                        messageData = [kVideoUrl: videoUrl as AnyObject, kImageUrl: "" as AnyObject, kImageWidth: "\(thumbnailImage.size.width)" as AnyObject, kImageHeight: "\(thumbnailImage.size.height)" as AnyObject, kFromId: self.senderId as AnyObject, kToId: self.receiverId as AnyObject, kTimestamp: timestamp as AnyObject, kGroupMessage: kNO as AnyObject]
                    }
                    else{
                        messageData = [kVideoUrl: videoUrl as AnyObject, kSenderName: (FIRAuth.auth()?.currentUser?.displayName)! as AnyObject as AnyObject, kImageUrl: "" as AnyObject, kImageWidth: "\(thumbnailImage.size.width)" as AnyObject, kImageHeight: "\(thumbnailImage.size.height)" as AnyObject, kFromId: self.senderId as AnyObject, kTimestamp: timestamp as AnyObject, kGroupMessage: kYES as AnyObject]
                    }
                    
                    //let messageData: [String: AnyObject] = ["videoUrl": videoUrl as AnyObject,"senderId": self.senderId as AnyObject, "receiverId": self.receiverId as AnyObject, "timestamp": timestamp as AnyObject]
                    let key = self.sendVideoMessage(info: messageData)
                    print("Video Message Key:",key!)
                }
            }
        })
        
        uploadtask.observe(.progress) { (snapshot) in
            if let completedUnitCount = snapshot.progress?.completedUnitCount {
                self.navigationItem.title = String(completedUnitCount)
            }
        }

        uploadtask.observe(.success) { (snapshot) in
            self.navigationItem.title = self.receiverDisplayName
        }
    }
    
    private func thumbnailImageForFileUrl(fileUrl: URL) -> UIImage? {
        
        let asset = AVAsset(url: fileUrl)
        let imageGenerator = AVAssetImageGenerator(asset: asset)
        
        do {
            let thumbnailImage = try imageGenerator.copyCGImage(at: CMTimeMake(1, 60), actualTime: nil)

            return UIImage(cgImage: thumbnailImage)
            
        } catch let error {
            print(error)
        }
        return nil
    }
    
    //MARK: - ImageViewer Methods -
    func itemCount() -> Int {
        
        return imageViews.count
    }
    
    func provideDisplacementItem(atIndex index: Int) -> DisplaceableView? {
        
        return imageViews[index]
    }
    
    func provideGalleryItem(_ index: Int) -> GalleryItem {
        
        /*(if index == 2 {
            
            return GalleryItem.video(fetchPreviewImageBlock: { $0(UIImage(named: "2")!)} , videoURL: URL(string: "http://video.dailymail.co.uk/video/mol/test/2016/09/21/5739239377694275356/1024x576_MP4_5739239377694275356.mp4")!)
        }
        if index == 4 {
            
            let myFetchImageBlock: FetchImageBlock = { [weak self] in $0(self?.imageViews[index].image!) }
            
            let itemViewControllerBlock: ItemViewControllerBlock = { index, itemCount, fetchImageBlock, configuration, isInitialController in
                
                return AnimatedViewController(index: index, itemCount: itemCount, fetchImageBlock: myFetchImageBlock, configuration: configuration, isInitialController: isInitialController)
            }
            
            return GalleryItem.custom(fetchImageBlock: myFetchImageBlock, itemViewControllerBlock: itemViewControllerBlock)
        }
        else {*/
            
            let image = imageViews[index].image ?? UIImage(named: "0")!
            
            return GalleryItem.image { $0(image) }
        //}
    }
    
    func galleryConfiguration() -> GalleryConfiguration {
        
        return [
            
            GalleryConfigurationItem.pagingMode(.standard),
            GalleryConfigurationItem.presentationStyle(.displacement),
            GalleryConfigurationItem.hideDecorationViewsOnLaunch(false),
            
            GalleryConfigurationItem.swipeToDismissHorizontally(false),
            GalleryConfigurationItem.toggleDecorationViewsBySingleTap(false),
            
            GalleryConfigurationItem.overlayColor(UIColor(white: 0.035, alpha: 1)),
            GalleryConfigurationItem.overlayColorOpacity(0.7),
            GalleryConfigurationItem.overlayBlurOpacity(0.7),
            GalleryConfigurationItem.overlayBlurStyle(UIBlurEffectStyle.light),
            
            GalleryConfigurationItem.maximumZoolScale(8),
            GalleryConfigurationItem.swipeToDismissThresholdVelocity(500),
            
            GalleryConfigurationItem.doubleTapToZoomDuration(0.15),
            
            GalleryConfigurationItem.blurPresentDuration(0.5),
            GalleryConfigurationItem.blurPresentDelay(0),
            GalleryConfigurationItem.colorPresentDuration(0.25),
            GalleryConfigurationItem.colorPresentDelay(0),
            
            GalleryConfigurationItem.blurDismissDuration(0.1),
            GalleryConfigurationItem.blurDismissDelay(0.4),
            GalleryConfigurationItem.colorDismissDuration(0.45),
            GalleryConfigurationItem.colorDismissDelay(0),
            
            GalleryConfigurationItem.itemFadeDuration(0.3),
            GalleryConfigurationItem.decorationViewsFadeDuration(0.15),
            GalleryConfigurationItem.rotationDuration(0.15),
            
            GalleryConfigurationItem.displacementDuration(0.55),
            GalleryConfigurationItem.reverseDisplacementDuration(0.25),
            GalleryConfigurationItem.displacementTransitionStyle(.springBounce(0.7)),
            GalleryConfigurationItem.displacementTimingCurve(.linear),
            
            GalleryConfigurationItem.statusBarHidden(true),
            GalleryConfigurationItem.displacementKeepOriginalInPlace(false),
            GalleryConfigurationItem.displacementInsetMargin(50)
        ]
    }
}

// MARK: Image Picker Delegate
extension ChatViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController,
                               didFinishPickingMediaWithInfo info: [String : Any]) {
        
        picker.dismiss(animated: true, completion:nil)
        
        if let videoUrl = info[UIImagePickerControllerMediaURL] as? URL {
            //we selected a video
            uploadVideoToFirebase(videoUrl)
        } else {
            //we selected an image
            uploadImageToFirebase(info as [String : AnyObject])
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion:nil)
    }
}

