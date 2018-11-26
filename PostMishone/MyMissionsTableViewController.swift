//
//  MyMissionsTableViewController.swift
//  PostMishone
//
//  Created by Victor Liang on 2018-11-07.
//  Copyright © 2018 Victor Liang. All rights reserved.
//

import UIKit
import Firebase


class MyMissionsTableViewController: UITableViewController {
    var ref: DatabaseReference!
    var missionIDS = [String]() // Stores each missionID of the user's "PostedMissions"
    var missionNames = [String]()
    let userID = Auth.auth().currentUser!.uid
    var selectedMission = ""

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.navigationItem.title = "My Missions"
        ref = Database.database().reference() //Firebase Reference
        ref?.child("Users").child(userID).child("MissionPosts").observe(.value, with: { (snapshot) in
            for child in snapshot.children {
                let snap = child as! DataSnapshot
                let missionID = snap.key
                let isUnderAcceptedMissions = snap.value as? Bool
                print(missionID)
                print(isUnderAcceptedMissions)
                
                if isUnderAcceptedMissions! { // Look under https://postmishone.firebaseio.com/AcceptedMissions
                    self.ref.child("AcceptedMissions").queryOrderedByKey().queryEqual(toValue: missionID).observeSingleEvent(of: .childAdded, with: { (snapshot) in
                        print("LOOKING IN ACCEPTEDMISSIONS")
                        print(snapshot)
                        if let dic = snapshot.value as? [String:Any], let missionName = dic["missionName"] as? String {
                            print(missionName)
                            self.missionNames.append(missionName)
                            self.missionIDS.append(missionID)
                            self.tableView.reloadData()
                        }
                    })
                }
                else { // Look under https://postmishone.firebaseio.com/PostedMissions
                    self.ref.child("PostedMissions").queryOrderedByKey().queryEqual(toValue: missionID).observeSingleEvent(of: .childAdded, with: { (snapshot) in
                        print("LOOKING IN POSTEDMISSIONS")
                        print(snapshot)
                        if let dic = snapshot.value as? [String:Any], let missionName = dic["missionName"] as? String {
                            print(missionName)
                            self.missionNames.append(missionName)
                            self.missionIDS.append(missionID)
                            self.tableView.reloadData()
                        }
                    })
                }
            }
        })
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return missionNames.count
    }


    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath)

        cell.textLabel?.text = missionNames[indexPath.row]

        return cell
    }
    
    // Bring user to ViewMyMission view controller based on the mission on list they selected
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedMission = missionIDS[indexPath.row]
        print(selectedMission)
        
        
        ref?.child("Users").child(userID).child("MissionPosts").observeSingleEvent(of: .value, with: { (snapshot) in

            if let dic = snapshot.value as? [String: Bool] {
                let isUnderAcceptedMissions = dic[self.selectedMission]
                if(isUnderAcceptedMissions!) {
                    print("toViewAcceptedMission")
                    self.performSegue(withIdentifier: "toViewAcceptedMission", sender: self)
                }
                else {
                    print("toViewMyMission")
                    self.performSegue(withIdentifier: "toViewMyMission", sender: self)
                }
                
            }
        })

    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "toViewMyMission" { // Posted Mission
            let destination = segue.destination as? ViewMyMission
            destination?.missionID = selectedMission
            destination?.enteredFromMap = false
        }
        
        if segue.identifier == "toViewAcceptedMission" {
            let destination = segue.destination as? ViewAcceptedMission
            destination?.missionID = selectedMission
        }
        
    }

}


