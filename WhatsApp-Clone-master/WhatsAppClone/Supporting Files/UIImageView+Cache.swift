//
//  UIImageView+Cache.swift
//  WhatsAppClone
//
//  Created by Sujal Bandhara on 01/01/2017.
//  Copyright © 2017 byPeople Technologies All rights reserved.
//

import UIKit
import Firebase
import JSQMessagesViewController

private var imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    func loadImageUsingCacheWithUrlString(urlString: String) {
        
        //self.image = nil
        
        //checkcache for image first
        if let cachedImage = imageCache.object(forKey: urlString as AnyObject) as? UIImage {
            
            self.image = JSQMessagesAvatarImageFactory.circularAvatarImage(cachedImage, withDiameter: 48)
            return
        }
        
        //otherwise fire off a new download
        FIRStorage.storage().reference(forURL: urlString).data(withMaxSize: 1*1024*1024*1024) { (data, error) in
            if error == nil {
                
                DispatchQueue.main.async(execute: {
                    
                    if let downloadedImage = UIImage(data: data!) {
                        
                        imageCache.setObject(downloadedImage, forKey: urlString as AnyObject)
                        
                        self.image = JSQMessagesAvatarImageFactory.circularAvatarImage(downloadedImage, withDiameter: 48)
                    }
                })
            } else {
                
                let alertView = SCLAlertView()
                alertView.showError("😁OOPS😁", subTitle: error!.localizedDescription)
            }
        }
    }
    
    func downloadedFrom(url: URL, contentMode mode: UIViewContentMode = .scaleAspectFit) {
        contentMode = mode
        URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard
                let httpURLResponse = response as? HTTPURLResponse, httpURLResponse.statusCode == 200,
                let mimeType = response?.mimeType, mimeType.hasPrefix("image"),
                let data = data, error == nil,
                let image = UIImage(data: data)
                else { return }
            DispatchQueue.main.async() { () -> Void in
                self.image = image
            }
            }.resume()
    }
}
