//
//  SettingsViewController.swift
//  PostMishone
//
//  Created by Victor Liang on 2018-10-14.
//  Copyright © 2018 Victor Liang. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import FBSDKCoreKit
import FBSDKLoginKit
import FirebaseStorage
import SwiftyJSON

class SettingsViewController: UIViewController {
    @IBOutlet weak var uiimgvpropic: UIImageView!
    @IBOutlet weak var uiname: UILabel!
    @IBOutlet weak var uiemail: UILabel!
    
    var imagePicker:UIImagePickerController!
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = true
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // make profile round
        self.uiimgvpropic.layer.cornerRadius = self.uiimgvpropic.frame.size.width/2
        self.uiimgvpropic.clipsToBounds = true
        
        let user = Auth.auth().currentUser
        let email = user?.email
        let uid = user?.uid
        
        // user signed in
        self.uiemail.text = email
        
        // fetch the username
        let username = Database.database().reference().child("Users").child(Auth.auth().currentUser!.uid)
        
        username.observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let name = value?["username"] as? String ?? ""
            self.uiname.text = name
        })
        
        // reference to firebase storage
        let store = Storage.storage()
        // refer our storage service
        let storeRef = store.reference(forURL: "gs://postmishone.appspot.com")
        // access files and paths
        let userProfilesRef = storeRef.child("images/profiles/\(uid!)")
        
        // check if the picture exist in the database
        userProfilesRef.getData(maxSize: 1*1024*1024) { (data, error) in
            if data != nil && error == nil{
                self.uiimgvpropic.image = UIImage(data: data!)
            } else {
                if FBSDKAccessToken.current() != nil {
                    FBSDKGraphRequest(graphPath: "/me", parameters: ["fields": "id, name, email, picture.width(480).height(480)"])?.start(completionHandler: { (connection, result, err) in
                        if err == nil {
                            let json = result as! [String: AnyObject]
                            ////
                            // Data in memory
                            let FBid = json["id"] as? String
                            
                            let nsurl = NSURL(string: "https://graph.facebook.com/\(FBid!)/picture?type=large&return_ssl_resources=1")
                            let imageData = UIImage(data: NSData(contentsOf: nsurl! as URL)! as Data)
                            guard let imgData = imageData?.jpegData(compressionQuality: 0.75) else {return}
                            
                            // metadata
                            let metaData = StorageMetadata()
                            metaData.contentType = "image/jpg"
                            
                            // Upload the file to the path "images/rivers.jpg"
                            let uploadTask = userProfilesRef.putData(imgData, metadata: metaData) { (metadata, error) in
                                guard let metadata = metadata else {
                                    // Uh-oh, an error occurred!
                                    print("Error metadata")
                                    return
                                }
                                // Metadata contains file metadata such as size, content-type.
                                let size = metadata.size
                                // You can also access to download URL after upload.
                                userProfilesRef.downloadURL { (url, error) in
                                    guard let downloadURL = url else {
                                        // Uh-oh, an error occurred!
                                        print("Error downloadURL")
                                        return
                                    }
                                }
                            }
                            self.uiimgvpropic.image = UIImage(data: imgData)
                            ////
                        } else {
                            print("Failed to start graph request")
                            return
                        }
                    })
                } else {
                    let none = Storage.storage().reference(forURL: "gs://postmishone.appspot.com").child("images/profiles/yolo123empty.jpg")
                    none.getData(maxSize: 1*1024*1024, completion: { (data_none, error_none) in
                        if error_none != nil {
                            print("error fetching the none profile pic")
                        } else {
                            self.uiimgvpropic.image = UIImage(data: data_none!)
                        }
                    })
                }
            }
        }
        view.accessibilityIdentifier = "SettingsViewController" // Identifier for UI Testing
        
        imagePicker = UIImagePickerController()
        imagePicker.allowsEditing = true
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func handleLogOut(_ sender: Any) {
        let firebaseAuth = Auth.auth()
        do {
            FBSDKAccessToken.setCurrent(nil)
            try firebaseAuth.signOut()
        } catch let signOutError as NSError {
            print ("Error signing out: %@", signOutError)
        }
        
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func imagePickerTapped(_ sender: Any) {
        self.present(imagePicker, animated: true, completion: nil)
    }
    
    
}


extension SettingsViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true, completion: nil)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        
        if let pickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            let user = Auth.auth().currentUser
            let uid = user?.uid
            // reference to firebase storage
            let userProfilesRef = Storage.storage().reference(forURL: "gs://postmishone.appspot.com").child("images/profiles/\(uid!)")
            
            // see if there already exist a picture in database, delete if yes
            userProfilesRef.getData(maxSize: 1*1024*1024) { (data, error) in
                if error != nil {
                    print("unable to download image")
                } else {
                    if data != nil {
                        userProfilesRef.delete(completion: { (err) in
                            if err != nil {
                                print("error deleting image")
                            }
                        })
                    }
                }
            }
            
            let userProfilesRef2 = Storage.storage().reference(forURL: "gs://postmishone.appspot.com").child("images/profiles/\(uid!)")
            
            guard let imgData = pickedImage.jpegData(compressionQuality: 0.75) else {return}
            
            // metadata
            let metaData = StorageMetadata()
            metaData.contentType = "image/jpg"
            
            // Upload the file to the path "images/rivers.jpg"
            let uploadTask = userProfilesRef2.putData(imgData, metadata: metaData) { (metadata, error) in
                guard let metadata = metadata else {
                    // Uh-oh, an error occurred!
                    print("Error metadata")
                    return
                }
                // Metadata contains file metadata such as size, content-type.
                let size = metadata.size
                // You can also access to download URL after upload.
                userProfilesRef2.downloadURL { (url, error) in
                    guard let downloadURL = url else {
                        // Uh-oh, an error occurred!
                        print("Error downloadURL")
                        return
                    }
                }
            }
            self.uiimgvpropic.image = pickedImage
            //            URLCache.shared.removeAllCachedResponses()
        }
        picker.dismiss(animated: true, completion: nil)
    }
    
}
