//
//  NewMessageTableViewController.swift
//  PostMishone
//
//  Created by Tiffany Tang on 21/11/2018.
//  Copyright © 2018 Victor Liang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class User: NSObject{
    var username: String?
    var email: String?
    var id: String?
    
}

class NewMessageTableViewController: UITableViewController {
    var ref: DatabaseReference!
    var myMissions = [String]()
    var missionIDS = [String]()
    let userID = Auth.auth().currentUser!.uid
    
    var users = [User]()
    let cellID = "cellID"
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "New Message"
        
        navigationItem.leftBarButtonItem = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(handleCancel))
        
        tableView.register(UserCell.self, forCellReuseIdentifier: cellID)
        
        fetchUser()
        
    }
    
    //get user from database
    func fetchUser(){
        Database.database().reference().child("Users").child(userID).child("FriendsList").observe(.childAdded, with: {(snapshot) in
            //  Database.database().reference().child("Users").observe(.childAdded, with: {(snapshot) in
            print(snapshot.value)
            
            /* if let dictionary = snapshot.value as? [String: AnyObject]{
             let user = User()
             user.id = dictionary["friend"] as? String
             print(user.id)
             print(user.id!) */
            
            let userId = snapshot.value
            
            Database.database().reference().child("Users").child(userId as! String).observeSingleEvent(of: .value, with: { (snapshot) in
                
                if let dictionary = snapshot.value as? [String: AnyObject]{
                    let usera = User()
                    usera.id = snapshot.key
                    print(usera.id!)
                    
                    usera.email = dictionary ["email"] as? String
                    usera.username = dictionary ["username"] as? String
                    self.users.append(usera)
                    DispatchQueue.main.async(execute: {self.tableView.reloadData()})
                }
            }, withCancel: nil)
            // }
        }, withCancel: nil)
    }
    
    
    // when cancel to create a new message
    @objc func handleCancel(){
        dismiss(animated: true, completion: nil)
    }
    
    // set number of rows in the table view
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return users.count
    }
    
    // data to show in each cell
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: cellID, for: indexPath) as! UserCell
        
        let user = users[indexPath.row]
        let toId = user.id
        
        cell.profileImageView.loadImageUsingCacheWithU(toId: toId!)
        cell.textLabel?.text = user.username
        cell.detailTextLabel?.text = user.email
        
        
        return cell
        
    }
    
    // height for each row/cell
    override  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 77
    }
    
    
    // when a row is being selected, first dismiss the new message view then direct to chatlog view
    // user that being selected is sent to the chat table view
    var chattableController: ChatTableViewController?
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        dismiss(animated: true){
            print("Dismiss completed")
            let user = self.users[indexPath.row]
            print(user)
            self.chattableController?.showChatControllerForUser(user: user)
            
        }
    }
}



