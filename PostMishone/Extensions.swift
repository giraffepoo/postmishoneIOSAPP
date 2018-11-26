//
//  Extensions.swift
//
//
//  Created by Tiffany Tang on 24/11/2018.
//

import UIKit
import FirebaseStorage

let imageCache = NSCache<AnyObject, AnyObject>()

extension UIImageView {
    
    // to stablize(cache) the profile image
    func loadImageUsingCacheWithU (toId: String)
    {
        
        self.image = nil
        
        //check cache for image first
        if let cachedImage = imageCache.object(forKey: toId as AnyObject) as? UIImage{
            self.image = cachedImage
            return
        }
        
        // otherwise fire off a new download
        
        // reference to firebase storage and access to file and path
        let userProfilesRef = Storage.storage().reference(forURL: "gs://postmishone.appspot.com").child("images/profiles/\(toId)")
        
        userProfilesRef.getData(maxSize: 1*1024*1024) { (data, error) in
            if data == nil {
                let none = Storage.storage().reference(forURL: "gs://postmishone.appspot.com").child("images/profiles/yolo123empty.jpg")
                none.getData(maxSize: 1*1024*1024, completion: { (data_none, error_none) in
                    if error_none != nil {
                        print("error fetching the none profile pic")
                    } else {
                        self.image = UIImage(named: "yolo123empty")
                    }
                })
            }
        }
        
        // check if the picture exist in the database
        userProfilesRef.getData(maxSize: 1*1024*1024) { (data, error) in
            if data != nil && error == nil{
                print(data as Any)
                
                if let downloadedImage = UIImage(data: data!){
                    imageCache.setObject(downloadedImage, forKey: toId as AnyObject)
                    
                    self.image = downloadedImage
                }
            }
        }
    }
}
