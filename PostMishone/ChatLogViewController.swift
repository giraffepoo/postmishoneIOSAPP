//
//  ChatLogController.swift
//  PostMishone
//
//  Created by Tiffany Tang on 21/11/2018.
//  Copyright © 2018 Victor Liang. All rights reserved.
//

import UIKit
import Firebase

class ChatLogViewController: UICollectionViewController, UITextFieldDelegate, UICollectionViewDelegateFlowLayout{
    
  var usera: User? {
       didSet{
        self.navigationItem.title = usera?.username
        observeMessages()
        }
    }
    
    var messages = [Message]()
  
    lazy var inputTextField: UITextField = {
        let textField = UITextField()
        textField.placeholder = "Enter message..."
        textField.translatesAutoresizingMaskIntoConstraints = false
        textField.delegate = self
        return textField
    }()
    
    let cellId = "cellId"
    
    override func viewDidLoad(){
        super.viewDidLoad()
        
        collectionView?.contentInset = UIEdgeInsets(top: 8, left: 0, bottom: 8, right: 0)
        collectionView?.alwaysBounceVertical = true
        collectionView?.backgroundColor = UIColor.white
        collectionView.register(ChatMessageCell.self, forCellWithReuseIdentifier: cellId)
        
        collectionView?.keyboardDismissMode = .interactive
        
       // setupInputComponents()
      //  setupKeyboardObservers()

        self.tabBarController?.tabBar.isHidden = true
    
        self.navigationItem.title = usera!.username
    }
    
    lazy var inputContainerView: UIView = {
        let containerView = UIView()
        containerView.frame = CGRect(x:0, y:0, width: self.view.frame.width, height: 50)
        containerView.backgroundColor = UIColor.white
        
        //initialize Send Button
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        
        // Place send button
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        // Init "Enter message..."
        containerView.addSubview(self.inputTextField)
        
        // Place "Enter message..."
        self.inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        self.inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        self.inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: 8).isActive = true
        self.inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor.darkGray
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
        
        return containerView
        
    }()
    
    override var inputAccessoryView: UIView? {
        get {
            return inputContainerView
        }
    }
    
    override var canBecomeFirstResponder: Bool {
        return true
    }
    
    func setupKeyboardObservers(){
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillShow), name: UIResponder.keyboardWillShowNotification, object: nil)
        
        NotificationCenter.default.addObserver(self, selector: #selector(handleKeyboardWillHide), name: UIResponder.keyboardWillHideNotification, object: nil)
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        NotificationCenter.default.removeObserver(self)
        
    }
    
    @objc func handleKeyboardWillHide(notification: NSNotification) {
            let keyboardDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
        
            containerViewBottonAnchor?.constant = 0
            UIView.animate(withDuration: keyboardDuration!) {
                self.view.layoutIfNeeded()
            }
    }
    
    @objc func handleKeyboardWillShow(notification: NSNotification) {
        
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardDuration = (notification.userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? NSNumber)?.doubleValue
 
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            
            containerViewBottonAnchor?.constant = -keyboardHeight
            UIView.animate(withDuration: keyboardDuration!) {
                self.view.layoutIfNeeded()
            }
        }
    }
    
    func observeMessages(){
        guard let userID = Auth.auth().currentUser?.uid else{
            return
        }
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(userID)
        userMessagesRef.observe(.childAdded, with: { (snapshot)in
           
            let messageId = snapshot.key
            let messagesRef = Database.database().reference().child("Messages").child(messageId)
            
            messagesRef.observeSingleEvent(of: .value, with: { (snapshot) in
                    
                guard let dictionary = snapshot.value as? [String: AnyObject] else{
                        return
                }
                    
                let message = Message()
                message.toId = dictionary["toId"] as? String
                message.fromId = dictionary["fromId"] as? String
                message.timeStamp = dictionary["timeStamp"] as? NSNumber
                message.text = dictionary["text"] as? String
                
                if message.chatPartnerId() == self.usera?.id {
                    self.messages.append(message)
                    DispatchQueue.main.async(execute: {self.collectionView.reloadData()})
                }
       
            }, withCancel: nil)
            
        }, withCancel: nil)
    }

    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        return messages.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: cellId, for: indexPath) as! ChatMessageCell
        
        let message = messages[indexPath.item]
        cell.textView.text = message.text
        
        setupCell(cell: cell, message: message)

        // modify the bubble view's width
        cell.bubbleWidthAnchor?.constant = estimateFrameForText(text: message.text!).width + 32
        
        return cell
    }
    
    private func setupCell(cell: ChatMessageCell, message: Message){
        if let toId = message.fromId {
        cell.profileImageView.loadImageUsingCacheWithU(toId: toId)
        }
        
        if message.fromId == Auth.auth().currentUser!.uid {
            // outgoing blue
            cell.bubbleView.backgroundColor = ChatMessageCell.blueColor
            cell.textView.textColor = UIColor.white 
            cell.profileImageView.isHidden = true
            
            cell.bubbleViewRightAnchor?.isActive = true
            cell.bubbleViewLeftAnchor?.isActive = false
   
        } else {
            //incoming gray
            cell.bubbleView.backgroundColor = UIColor.lightGray
            cell.textView.textColor = UIColor.black
            cell.profileImageView.isHidden = false
            
            cell.bubbleViewRightAnchor?.isActive = false
            cell.bubbleViewLeftAnchor?.isActive = true
     
        }
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        collectionView?.collectionViewLayout.invalidateLayout()
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        
        var height: CGFloat = 80
        
        if let text = messages[indexPath.item].text {
            height = estimateFrameForText(text: text).height + 20
        }
        
        return CGSize(width: view.frame.width, height: height)
    }
    
    private func estimateFrameForText (text: String) -> CGRect {
        let size = CGSize(width: 200, height: 1000)
        let options = NSStringDrawingOptions.usesFontLeading.union(.usesLineFragmentOrigin)
        
        return NSString(string:text).boundingRect(with: size, options: options, attributes: [NSAttributedString.Key.font: UIFont.systemFont(ofSize: 16)], context: nil)
    }
    
    // send message to database
    @objc func handleSend(){
        let ref = Database.database().reference().child("Messages")
       
        let childRef = ref.childByAutoId()
        let messageId = childRef.key
        

        let toId = usera?.id
        let fromId = Auth.auth().currentUser!.uid
        let timeStamp = NSDate().timeIntervalSince1970
        let values = ["text": inputTextField.text!, "toId": toId as Any, "fromId": fromId, "timeStamp": timeStamp]
        
        let userMessagesRef = Database.database().reference().child("user-messages").child(fromId)
        let recipientUserMessagesRef = Database.database().reference().child("user-messages").child(toId!)
        
        let testing = [messageId: 1]
        
        childRef.updateChildValues(values) { (error, ref) in
            if error != nil{
                print(error as Any)
                return
            }
            
            self.inputTextField.text = nil
            
            userMessagesRef.updateChildValues(testing as [AnyHashable : Any])
            recipientUserMessagesRef.updateChildValues(testing as [AnyHashable : Any])
        }
    }

    // set "enter" as the send button also
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        handleSend()
        return true
    }
    
    var containerViewBottonAnchor: NSLayoutConstraint?
    
    func setupInputComponents(){
        let containerView = UIView()
        containerView.backgroundColor = UIColor.white
        containerView.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(containerView)
        
        // Place the text field box at the bottom
        containerView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        
        containerViewBottonAnchor = containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        containerViewBottonAnchor?.isActive = true
        
        containerView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        
        containerView.heightAnchor.constraint(equalToConstant: 100).isActive = true
        
        //initialize Send Button
        let sendButton = UIButton(type: .system)
        sendButton.setTitle("Send", for: .normal)
        sendButton.translatesAutoresizingMaskIntoConstraints = false
        sendButton.addTarget(self, action: #selector(handleSend), for: .touchUpInside)
        containerView.addSubview(sendButton)
        
        // Place send button
        sendButton.rightAnchor.constraint(equalTo: containerView.rightAnchor).isActive = true
        sendButton.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        sendButton.widthAnchor.constraint(equalToConstant: 80).isActive = true
        sendButton.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        // Init "Enter message..."
        containerView.addSubview(inputTextField)
        
        // Place "Enter message..."
        inputTextField.leftAnchor.constraint(equalTo: containerView.leftAnchor, constant: 8).isActive = true
        inputTextField.centerYAnchor.constraint(equalTo: containerView.centerYAnchor).isActive = true
        inputTextField.rightAnchor.constraint(equalTo: sendButton.leftAnchor, constant: 8).isActive = true
        inputTextField.heightAnchor.constraint(equalTo: containerView.heightAnchor).isActive = true
        
        let separatorLineView = UIView()
        separatorLineView.backgroundColor = UIColor.darkGray
        separatorLineView.translatesAutoresizingMaskIntoConstraints = false
        containerView.addSubview(separatorLineView)
        
        separatorLineView.leftAnchor.constraint(equalTo: containerView.leftAnchor).isActive = true
        separatorLineView.topAnchor.constraint(equalTo: containerView.topAnchor).isActive = true
        separatorLineView.widthAnchor.constraint(equalTo: containerView.widthAnchor).isActive = true
        separatorLineView.heightAnchor.constraint(equalToConstant: 1).isActive = true
        
    }
    
}
