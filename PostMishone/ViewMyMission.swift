//
//  ViewMyMission.swift
//  PostMishone
//
//  Created by Victor Liang on 2018-11-24.
//  Copyright © 2018 Victor Liang. All rights reserved.
//

import UIKit
import Firebase

class ViewMyMission: UIViewController {
    @IBOutlet weak var missionTitleTextField: UITextField!
    @IBOutlet weak var missionDescriptionTextView: UITextView!
    @IBOutlet weak var missionRewardTextField: UITextField!
    
    var ref: DatabaseReference!
    let userID = Auth.auth().currentUser!.uid
    var missionID = ""
    var posterID = ""
    var enteredFromMap = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ref = Database.database().reference() // Firebase Reference
        let borderColor : UIColor = UIColor(red: 0.85, green: 0.85, blue: 0.85, alpha: 1.0)
        missionDescriptionTextView.layer.borderWidth = 0.5
        missionDescriptionTextView.layer.borderColor = borderColor.cgColor
        missionDescriptionTextView.layer.cornerRadius = 5.0
        
        ref?.child("PostedMissions").child(missionID).observeSingleEvent(of: .value, with: { (snapshot) in
           if let dic = snapshot.value as? [String:Any], let missionName = dic["missionName"] as? String, let missionDescription = dic["missionDescription"] as? String, let reward = dic["reward"] as? String, let posterID = dic["UserID"] as? String? {
            self.missionTitleTextField.text = missionName
            self.missionDescriptionTextView.text = missionDescription
            self.missionRewardTextField.text = reward
            self.posterID = posterID!
            }
        })
        
    }
    
    
    @IBAction func deleteMission(_ sender: Any) {
        print("deleteMission")
        // Remove from https://postmishone.firebaseio.com/PostedMissions
        self.ref.child("PostedMissions").child(missionID).removeValue()
        
        // Remove from https://postmishone.firebaseio.com/users/(currentuserid)/
        self.ref.child("Users").child(posterID).child("MissionPosts").child(missionID).removeValue()
        
        if(enteredFromMap) {
            print("POP ONE")
            self.navigationController?.popViewController(animated: true)
        }
        else {
            print("POP TWO")
            backTwo()
        }
        
    }
    
    
    @IBAction func updateMission(_ sender: Any) {
//        print("updated values: \(miss)")
        ref?.child("PostedMissions").child(missionID).updateChildValues(["missionName" : missionTitleTextField.text!])
        ref?.child("PostedMissions").child(missionID).updateChildValues(["missionDescription" : missionDescriptionTextView.text!])
        ref?.child("PostedMissions").child(missionID).updateChildValues(["reward" : missionRewardTextField.text!])
        
        if(enteredFromMap) {
            print("POP ONE")
            self.navigationController?.popViewController(animated: true)
        }
        else {
            print("POP TWO")
            backTwo()
        }
    }
    
    func backTwo() {
        let viewControllers: [UIViewController] = self.navigationController!.viewControllers as [UIViewController]
        self.navigationController!.popToViewController(viewControllers[viewControllers.count - 3], animated: true)
    }
    
    

}
