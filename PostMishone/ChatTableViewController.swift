//
//  ChatTableViewController.swift
//  PostMishone
//
//  Created by Tiffany Tang on 21/11/2018.
//  Copyright © 2018 Victor Liang. All rights reserved.
//

import UIKit
import Firebase
import FirebaseStorage

class Message: NSObject{
    
    var fromId: String?
    var text: String?
    var timeStamp: NSNumber?
    var toId: String?
    
    
    func chatPartnerId() -> String? {
        return fromId == Auth.auth().currentUser!.uid ? toId : fromId
    }
}


class ChatTableViewController: UITableViewController {
    var ref: DatabaseReference!
    let userID = Auth.auth().currentUser!.uid
    var usera = User() 
    let cellId = "cellId"
    
    override func viewDidLoad() {

        super.viewDidLoad()
        
        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.tabBarController?.tabBar.isHidden = false
   
        // that icon on the top right
//        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem(rawValue: 7)!, target: self, action: #selector(handleNewMessage))

        tableView.register(UserCell.self, forCellReuseIdentifier: cellId)
        
       // self.tabBarController?.tabBar.isHidden = false
        
        observeUserMessages()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem(rawValue: 7)!, target: self, action: #selector(handleNewMessage))
        self.tabBarController?.tabBar.isHidden = false
    }
    
    var messages = [Message]()
    var messagesDictionary = [String: Message]()
    
    func observeUserMessages(){
        guard let userID = Auth.auth().currentUser?.uid else{
            return
        }
        let ref = Database.database().reference().child("user-messages").child(userID)
        ref.observe(.childAdded, with: { (snapshot) in
            

            let messageId = snapshot.key
            let messageReference = Database.database().reference().child("Messages").child(messageId)
            
            messageReference.observeSingleEvent(of: .value, with: ({ (snapshot) in
            
                if let dictionary = snapshot.value as? [String: AnyObject]{
                    let message = Message()
                    
                    message.toId = dictionary["toId"] as? String
                    message.fromId = dictionary["fromId"] as? String
                    message.timeStamp = dictionary["timeStamp"] as? NSNumber
                    message.text = dictionary["text"] as? String
                    self.messages.append(message)
                    
                    
                    if let chatPartnerId = message.chatPartnerId(){
                        self.messagesDictionary[chatPartnerId] = message
                        
                        self.messages = Array(self.messagesDictionary.values)
                        self.messages.sort(by: { (message1, message2) -> Bool in
                            let m1time = message1.timeStamp!.intValue
                            let m2time = message2.timeStamp!.intValue
                            
                            return m1time > m2time
                        })
                    }
                    
                    self.timer?.invalidate()
                   self.timer = Timer.scheduledTimer(timeInterval: 0.1, target: self, selector: #selector(self.handleReloadTable), userInfo: nil, repeats: false)
                    
                }

            }), withCancel: nil)
            
        }, withCancel: nil)
    }
    
    var timer: Timer?
    
    @objc func handleReloadTable(){
        DispatchQueue.main.async(execute: {self.tableView.reloadData()})
    }
    
   // directing to chatlog view accoring to the person you want to talk to
    @objc func showChatControllerForUser(user: User){
        let chatLogController = ChatLogViewController(collectionViewLayout: UICollectionViewFlowLayout())
        //ChatLogViewController().setTitle(user: user)
        
        chatLogController.usera = user
        self.usera = user
        
        print("end")
        self.performSegue(withIdentifier: "toChatLog", sender: self)
        print("123456")
    }
    
    override func prepare (for segue: UIStoryboardSegue, sender: Any?){
        var vc = segue.destination as! ChatLogViewController
        vc.usera = usera
    }
    
    // when new message button is pressed
    @objc  func handleNewMessage(){
        let newMessageController = NewMessageTableViewController()
        newMessageController.chattableController = self
        let navController = UINavigationController(rootViewController: newMessageController)
        present(navController , animated: true, completion: nil)
    }
    // MARK: - Table view data source

    // data showing in each row
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: cellId, for: indexPath) as! UserCell
        
        let message = messages[indexPath.row]
        cell.message = message
        
        return cell
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return messages.count
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
      let message = messages[indexPath.row]
        
        guard let chatPartnerId = message.chatPartnerId() else {
            return
        }
        
        let ref = Database.database().reference().child("Users").child(chatPartnerId)
        ref.observeSingleEvent(of: .value
            , with: { (snapshot) in
                guard let dictionary = snapshot.value as? [String: AnyObject]
                    else {
                        return
                }
                
                let user = User()
                user.email = dictionary["email"] as? String
                user.username = dictionary["username"] as? String
                user.id = chatPartnerId
                self.showChatControllerForUser(user: user)
                
        }, withCancel: nil)
    }
    
    // height for each row/cell
    override  func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 77
    }

}


