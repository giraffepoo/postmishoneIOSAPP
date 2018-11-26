//
//  ViewProfile.swift
//  PostMishone
//
//  Created by Victor Liang on 2018-11-26.
//  Copyright © 2018 Victor Liang. All rights reserved.
//

import UIKit
import Firebase

class ViewProfile: UIViewController {
    var posterID = ""
    var user = User()
    var friends = [String]()
    
    @IBOutlet weak var posterimg: UIImageView!
    @IBOutlet weak var postername: UILabel!
    @IBOutlet weak var posteremail: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        // Do any additional setup after loading the view.
        // fetch the username
        let username = Database.database().reference().child("Users").child(posterID)
        
        username.observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let name = value?["username"] as? String ?? ""
            self.postername.text = name
        })
        
        // fetch the email
        let useremail = Database.database().reference().child("Users").child(posterID)
        
        useremail.observeSingleEvent(of: .value, with: { (snapshot) in
            let value = snapshot.value as? NSDictionary
            let name = value?["email"] as? String ?? ""
            self.posteremail.text = name
        })
        
        
        // check if the picture exist in the database
        // reference to firebase storage
        let store = Storage.storage()
        // refer our storage service
        let storeRef = store.reference(forURL: "gs://postmishone.appspot.com")
        // access files and paths
        let userProfilesRef = storeRef.child("images/profiles/\(posterID)")
        
        let ref = Database.database().reference().child("Users").child(posterID)
        ref.observeSingleEvent(of: .value
            , with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String: AnyObject]
                    else {
                        return
                }
                
                self.user.username = dictionary["username"] as? String
                
        }, withCancel: nil)
        
        userProfilesRef.getData(maxSize: 1*1024*1024) { (data, error) in
            if data != nil && error == nil{
                self.posterimg.image = UIImage(data: data!)
            } else {
                let none = Storage.storage().reference(forURL: "gs://postmishone.appspot.com").child("images/profiles/yolo123empty.jpg")
                none.getData(maxSize: 1*1024*1024, completion: { (data_none, error_none) in
                    if error_none != nil {
                        print("error fetching the none profile pic")
                    } else {
                        self.posterimg.image = UIImage(data: data_none!)
                    }
                })
            }
            
        }
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func addFriend(_ sender: Any) {
        // reference to firebase storage
        let userID = Auth.auth().currentUser!.uid
        let ref = Database.database().reference().child("Users").child(userID).child("FriendsList").child(posterID)
        
        ref.setValue(posterID)
        
        var frdAdded = UIAlertController(title: "Friend added", message: "Start chatting!", preferredStyle: UIAlertController.Style.alert);
        
        let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (Action) in
            print("OK button tapped")
        };
        
        frdAdded.addAction(okAction);
        
        self.present(frdAdded, animated: true, completion: nil);
    }
    
    var chattableController: ChatTableViewController?
    
    @IBAction func jumpToChat(_ sender: Any) {
        user.id = posterID
    }
    
    override func prepare (for segue: UIStoryboardSegue, sender: Any?){
        var vc = segue.destination as! ChatLogViewController
        vc.usera = user
    }
    
}
