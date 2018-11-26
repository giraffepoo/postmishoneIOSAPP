//
//  UserCell.swift
//  PostMishone
//
//  Created by Tiffany Tang on 24/11/2018.
//  Copyright © 2018 Victor Liang. All rights reserved.
//

import UIKit
import Firebase

class UserCell: UITableViewCell{
    
    var message: Message? {
        didSet{
            
            setupNameAndProfileImage()
            
            detailTextLabel?.text = message?.text
            
            if let seconds = message?.timeStamp?.doubleValue{
                let timestampDate = NSDate(timeIntervalSince1970: seconds)
                
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "hh:mm:ss a"
                
                timeLabel.text = dateFormatter.string(from: timestampDate as Date)
            }
            
            
        }
    }
    
    private func setupNameAndProfileImage (){
        
        if let id = message?.chatPartnerId() {
            
            let store = Storage.storage()
            // refer our storage service
            let storeRef = store.reference(forURL: "gs://postmishone.appspot.com")
            // access files and paths
            let userProfilesRef = storeRef.child("images/profiles/\(id)")
            
            userProfilesRef.getData(maxSize: 1*1024*1024) { (data, error) in
                if data == nil {
                    let none = Storage.storage().reference(forURL: "gs://postmishone.appspot.com").child("images/profiles/yolo123empty.jpg")
                    none.getData(maxSize: 1*1024*1024, completion: { (data_none, error_none) in
                        if error_none != nil {
                            print("error fetching the none profile pic")
                        } else {
                            self.profileImageView.image = UIImage(named: "yolo123empty")
                        }
                    })
                }
            }
            
            let ref = Database.database().reference().child("Users").child(id)
            ref.observeSingleEvent(of: .value, with: {(snapshot)
                in
                
                if let dictionary = snapshot.value as? [String: AnyObject]
                {
                    
                    self.textLabel?.text = dictionary["username"] as? String
                    self.profileImageView.loadImageUsingCacheWithU(toId: id)
                }
            }, withCancel: nil)
        }
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // change frame of text label
        let textLabelRect = CGRect(origin: CGPoint(x: 75,y :textLabel!.frame.origin.y - 2), size: CGSize(width: textLabel!.frame.width, height: textLabel!.frame.height ))
        
        textLabel?.frame = textLabelRect
        
        let detailTextLabelRect = CGRect(origin: CGPoint(x: 75,y :detailTextLabel!.frame.origin.y + 2), size: CGSize(width: detailTextLabel!.frame.width, height: detailTextLabel!.frame.height ))
        
        detailTextLabel?.frame = detailTextLabelRect
        
        
    }
    
    let profileImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.layer.cornerRadius = 30
        imageView.layer.masksToBounds = true
        imageView.contentMode = .scaleAspectFill
        return imageView
    }()
    
    let timeLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 13)
        label.textColor = UIColor.darkGray
        label.translatesAutoresizingMaskIntoConstraints = false
        return label
    }()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: .subtitle, reuseIdentifier: reuseIdentifier)
        
        addSubview(profileImageView)
        addSubview(timeLabel)
        
        // constraints
        profileImageView.leftAnchor.constraint(equalTo: self.leftAnchor, constant: 8).isActive = true
        profileImageView.centerYAnchor.constraint(equalTo: self.centerYAnchor).isActive = true
        profileImageView.widthAnchor.constraint(equalToConstant: 60).isActive = true
        profileImageView.heightAnchor.constraint(equalToConstant: 60).isActive = true
        
        timeLabel.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        timeLabel.topAnchor.constraint(equalTo: self.topAnchor, constant: 17).isActive = true
        timeLabel.widthAnchor.constraint(equalToConstant: 100).isActive = true
        timeLabel.heightAnchor.constraint(equalTo: (textLabel?.heightAnchor)! ).isActive = true
        
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
