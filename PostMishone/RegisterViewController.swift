//
//  RegisterViewController.swift
//  PostMishone
//
//  Created by Victor Liang on 2018-10-14.
//  Copyright © 2018 Victor Liang. All rights reserved.
//

import UIKit
import Firebase
import GoogleSignIn

class RegisterViewController : UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var nameTextField: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func registerTapped(_ sender: Any) {
        // Set up a new user on our Firebase database
        guard let email = emailTextField.text else { return }
        guard let password = passwordTextField.text else { return }
        guard let name = nameTextField.text else {return}
        
        if(name.count == 0) {
            let nError = UIAlertController(title: "Error", message: "Please enter your name.", preferredStyle: UIAlertController.Style.alert);
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (Action) in
                print("OK button tapped")
            };
            
            nError.addAction(okAction);
            
            self.present(nError, animated: true, completion: nil);
        }
        
        if(password.count >= 6) {
            Auth.auth().createUser(withEmail: email, password: password) { (user, error) in
                if error == nil && user != nil {
                    let userID = Auth.auth().currentUser!.uid
                    let values = ["username": name,"email": email, "balance": 0.0] as [String : Any]
                    self.registerUserIntoDatabase(userID, values: values as [String : AnyObject])
                    
                    self.navigationController?.popViewController(animated: false)
                    
                    
                    
                    print("Registration Successful")
                    
                } else {
                    print("Error registering")
                    print(error!)
                    
                }
            }
        } else {
            let loginError = UIAlertController(title: "Error", message: "Password too short.", preferredStyle: UIAlertController.Style.alert);
            
            let okAction = UIAlertAction(title: "OK", style: UIAlertAction.Style.default) { (Action) in
                print("OK button tapped")
            };
            
            loginError.addAction(okAction);
            
            self.present(loginError, animated: true, completion: nil);
        }
    }
    
    
    //CHANGE THIS TO ADD MORE PROFILE STUFF
    private func registerUserIntoDatabase(_ userID: String, values: [String: AnyObject]) {
        // Adding User Info
        let ref = Database.database().reference()
        let usersReference = ref.child("Users").child(userID)
        
        usersReference.updateChildValues(values, withCompletionBlock: { (err, ref) in
            if err != nil {
                print(err!)
                return
            }
            print("Successfully Added a New User to the Database")
        })
    }
}


