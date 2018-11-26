//
//  DescribeMissionViewController.swift
//  PostMishone
//
//  Created by Victor Liang on 2018-10-14.
//  Copyright © 2018 Victor Liang. All rights reserved.
//
import UIKit
import Firebase
import MapKit
import CoreLocation

class DescribeMissionViewController: UIViewController, UIPickerViewDataSource, UIPickerViewDelegate, UITextFieldDelegate {
    
    var ref: DatabaseReference!
    var latitude = 0.0
    var longitude = 0.0
    var selectedPriority : String?
    var missionCategories = ["", "Deliver", "Partner", "Rent", "Other"]
    var myPickerView : UIPickerView!

    
    @IBOutlet weak var missionName: UITextField!
    @IBOutlet weak var missionDescription: UITextField!
    @IBOutlet weak var reward: UITextField!
    @IBOutlet weak var missionCategory: UITextField!
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        return missionCategories.count
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        return missionCategories[row]
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        self.missionCategory.text = missionCategories[row]
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        self.pickUp(missionCategory)
    }
    
    func createPickerView() {
        let pickerView = UIPickerView()
        pickerView.delegate = self
        
        missionCategory.inputView = pickerView
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.isNavigationBarHidden = false
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        view.accessibilityIdentifier = "DescribeMissionViewController" // Identifier for UI Testing

        missionName.delegate = self
        missionDescription.delegate = self
        reward.delegate = self

        pickUp(missionCategory) // Load picker view (to select categories)
        
        // Do any additional setup after loading the view.
        ref = Database.database().reference() // Firebase Reference
    }
    
    // MARK: POSTING MISSION
    @IBAction func postMissionPressed(_ sender: Any) {
        guard let mName = missionName.text else { return }
        guard let mDescription = missionDescription.text else { return }
        guard let mReward = reward.text else {return}
        guard let mCategory = missionCategory.text else {return}
        
        if(mName.count == 0) {
            
            let nameError = UIAlertController(title: "Error", message: "Please specify mission name.", preferredStyle: UIAlertController.Style.alert);
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (Action) in
                print("OK button tapped")
            };
            
            nameError.addAction(okAction);
            
            self.present(nameError, animated: true, completion: nil);
            
        } else if(mDescription.count == 0) {
            
            let dError = UIAlertController(title: "Error", message: "Please enter mission description.", preferredStyle: UIAlertController.Style.alert);
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (Action) in
                print("OK button tapped")
            };
            
            dError.addAction(okAction);
            
            self.present(dError, animated: true, completion: nil);
            
        } else if(Int(mReward) == nil) {
            
            let rError = UIAlertController(title: "Error", message: "Please enter numbers only for reward.", preferredStyle: UIAlertController.Style.alert);
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (Action) in
                print("OK button tapped")
            };
            
            rError.addAction(okAction);
            
            self.present(rError, animated: true, completion: nil);
            
        } else if(mCategory.count == 0) {
            
            let cError = UIAlertController(title: "Error", message: "Please enter category for mission.", preferredStyle: UIAlertController.Style.alert);
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (Action) in
                print("OK button tapped")
            };
            
            cError.addAction(okAction);
            
            self.present(cError, animated: true, completion: nil);
            
        } else {
            let userID = Auth.auth().currentUser!.uid
            let timeStamp = Int(NSDate.timeIntervalSinceReferenceDate*1000)
            
            print("Describe Mission View Controller:")
            print("lat: ", latitude)
            print("long: ", longitude)
            print("userID: ", userID)
            print("timeStamp: ", timeStamp)
            print("missionNameText: ", missionName.text!)
            print("missionDescription: ", missionDescription.text!)
            print("reward: ", reward.text!)
            print("category: ", missionCategory.text!)
            
            
            let missionID = ref.child("PostedMissions").childByAutoId().key
            // Add to https://postmishone.firebaseio.com/PostedMissions
            ref?.child("PostedMissions").child(missionID!).setValue(["Latitude": latitude, "Longitude": longitude, "UserID": userID, "timeStamp": timeStamp, "missionName": missionName.text!, "missionDescription": missionDescription.text!, "reward": reward.text!, "missionID": missionID!, "category" : missionCategory.text!])
            
            // Add to https://postmishone.firebaseio.com/users/(currentuserid)/
            ref?.child("Users").child(userID).child("MissionPosts").child(missionID!).setValue(false)
            
            
            
            print("Mission Posted!")
            
            self.navigationController?.popViewController(animated: true)
        }
    }
    
    
    // Make keyboard close on return key press
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        return true
    }
    
    func dismissPickerView() {
        let toolBar = UIToolbar()

        let doneButton = UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.plain, target: self, action: Selector(("donePicker")))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: UIBarButtonItem.Style.plain, target: self, action: Selector(("donePicker")))
        
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        missionCategory.inputAccessoryView = toolBar

    }
    

    func pickUp(_ textField : UITextField){
        // UIPickerView
        self.myPickerView = UIPickerView(frame:CGRect(x: 0, y: 0, width: self.view.frame.size.width, height: 216))
        self.myPickerView.delegate = self
        self.myPickerView.dataSource = self
        self.myPickerView.backgroundColor = UIColor.white
        textField.inputView = self.myPickerView
        
        // ToolBar
        let toolBar = UIToolbar()
        toolBar.barStyle = .default
        toolBar.isTranslucent = true
        toolBar.tintColor = UIColor(red: 92/255, green: 216/255, blue: 255/255, alpha: 1)
        toolBar.sizeToFit()
        
        // Adding Button ToolBar
        let doneButton = UIBarButtonItem(title: "Done", style: .plain, target: self, action: #selector(DescribeMissionViewController.doneClick))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let cancelButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(DescribeMissionViewController.cancelClick))
        toolBar.setItems([cancelButton, spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        textField.inputAccessoryView = toolBar
        
    }
    
    @objc func doneClick() {
        missionCategory.resignFirstResponder()
    }
    @objc func cancelClick() {
        missionCategory.resignFirstResponder()
    }
    
    
}
