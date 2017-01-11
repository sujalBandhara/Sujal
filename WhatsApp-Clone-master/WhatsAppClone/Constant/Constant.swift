//
//  Constant.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//


import UIKit

let appDelegate = UIApplication.shared.delegate as! AppDelegate

let kApplicationName = "WhatsApp Clone"

//MARK: - Storage Folder-Name Constans

let kUserProfileImages = "user_profile_images"
let kGroupProfileImages = "group_profile_images"
let kUserMessagesImages = "user_messages_images"
let kGroupMessagesImages = "group_messages_images"
let kUserMessagesVideos = "user_messages_videos"
let kGroupMessagesVideos = "group_messages_videos"

let kUsers = "users"
let kGroups = "groups"
let kChatRooms = "chatRooms"
let kMessages = "messages"
let kUserMessages = "user-messages"

//MARK: - User -

let kUid = "uid"
let kUserName = "username"
let kEmail = "email"
let kBiography = "biography"
let kCountry = "country"
let kCountryCode = "countryCode"
let kProfileImageUrl = "profileImageUrl"

let kGroupIds = "groupIds"
let kConnections = "connections"
let kOnline = "online"
let kLastOnline = "last_online"

//MARK: - Group -

let kGroupId = "groupId"
let kGroupName = "groupName"
let kCreatorName = "creatorName"
let kCreatoId = "creatorId"
let kCreatedDate = "createdDate"
let kMembersCount = "membersCount"
let kGroupMembers = "groupMembers"
let kGroupImageUrl = "groupImageUrl"

//MARK: - Message -

let kFromId = "fromId"
let kToId = "toId"
let kSenderName = "senderDisplayName"
let kReceiverName = "receiverDisplayName"
let kTimestamp = "timestamp"
let kText = "text"
let kImageUrl = "imageUrl"
let kImageWidth = "imageWidth"
let kImageHeight = "imageHeight"
let kVideoUrl = "videoUrl"
let kGroupMessage = "isGroupMessage"
let kYES = "YES"
let kNO = "NO"

//MARK: - Requests -

let kRequests = "requests"
let kUserRequests = "user-requests"
let kSent = "sent"
let kAccepted = "accepted"
let kReceived = "received"

func showAlert(controller: UIViewController, message: String, title: String) {
    
    let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
    let OKAction = UIAlertAction(title: "OK", style: .default, handler: nil)
    alertController.addAction(OKAction)
    controller.present(alertController, animated: true, completion: nil)
}
