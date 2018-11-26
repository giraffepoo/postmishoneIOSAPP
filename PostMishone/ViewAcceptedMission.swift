//
//  ViewAcceptedMission.swift
//  PostMishone
//
//  Created by Victor Liang on 2018-11-26.
//  Copyright © 2018 Victor Liang. All rights reserved.
//

import UIKit
import Firebase

class ViewAcceptedMission: UIViewController, PayPalPaymentDelegate {
    @IBOutlet weak var mtitle: UILabel!
    @IBOutlet weak var mreward: UILabel!
    @IBOutlet weak var mdescription: UITextView!
    @IBOutlet weak var mname: UILabel!
    
    var ref: DatabaseReference!
    let userID = Auth.auth().currentUser!.uid
    var missionID = ""
    var PID = ""
    var reward = ""
    var missionTitle = ""
    var subtitle = ""
    
    //create paypal object
    var payPalConfig = PayPalConfiguration()
    
    //declare payment config
    var environment:String = PayPalEnvironmentNoNetwork {
        willSet(newEnvironment) {
            if (newEnvironment != environment) {
                PayPalMobile.preconnect(withEnvironment: newEnvironment)
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ref = Database.database().reference() // Firebase Reference
        
        ref?.child("AcceptedMissions").child(missionID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let dic = snapshot.value as? [String:Any], let missionName = dic["missionName"] as? String, let missionDescription = dic["missionDescription"] as? String, let reward = dic["reward"] as? String, let posterID = dic["UserID"] as? String? {
                self.mtitle.text = missionName
                self.missionTitle = missionName
                self.mdescription.text = missionDescription
                self.subtitle = missionDescription
                self.mreward.text = "$" + reward
                self.reward = reward
                self.PID = posterID!
                
                // fetch the username
                let username = Database.database().reference().child("Users").child(posterID!)
                
                username.observeSingleEvent(of: .value, with: { (snapshot) in
                    let value = snapshot.value as? NSDictionary
                    let name = value?["username"] as? String ?? ""
                    self.mname.text = name
                })
            }
        })
        
        // Do any additional setup after loading the view.
        payPalConfig.acceptCreditCards = false
        payPalConfig.merchantName = "PostMission, Inc."   // need to be changed
        payPalConfig.merchantPrivacyPolicyURL = URL(string: "https://www.paypal.com/webapps/mpp/ua/privacy-full")
        payPalConfig.merchantUserAgreementURL = URL(string: "https://www.paypal.com/webapps/mpp/ua/useragreement-full")
        // Setting the languageOrLocale property is optional.
        
        payPalConfig.languageOrLocale = Locale.preferredLanguages[0]
        
        // Setting the payPalShippingAddressOption property is optional.
        
        payPalConfig.payPalShippingAddressOption = .payPal;
        print("PayPal iOS SDK Version: \(PayPalMobile.libraryVersion())")
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destination.
        // Pass the selected object to the new view controller.
    }
    */
    @IBAction func paypalpayment(_ sender: Any) {
        //add payment items and related details
        
        //process payment once the pay button is clicked
        
        //let reward = self.ref.child("PostedMissions").child(missionID).child("reward").description()
        
        
        let item1 = PayPalItem(name: "Mission", withQuantity: 1, withPrice: NSDecimalNumber(string: reward), withCurrency: "USD", withSku: "PostMission")
        
        let items = [item1]
        let subtotal = PayPalItem.totalPrice(forItems: items)
        
        // Optional: include payment details
        let shipping = NSDecimalNumber(string: "0.00")
        let tax = NSDecimalNumber(string: "0.00")
        let paymentDetails = PayPalPaymentDetails(subtotal: subtotal, withShipping: shipping, withTax: tax)
        
        let total = subtotal.adding(shipping).adding(tax)
        
        let payment = PayPalPayment(amount: total, currencyCode: "USD", shortDescription: "Price of this mission", intent: .sale)
        
        payment.items = items
        payment.paymentDetails = paymentDetails
        
        if (payment.processable) {
            
            let paymentViewController = PayPalPaymentViewController(payment: payment, configuration: payPalConfig, delegate: self)
            present(paymentViewController!, animated: true, completion: nil)
        }
        else {
            
            print("Payment not processalbe: \(payment)")
        }
    }
    
    func payPalPaymentDidCancel(_ paymentViewController: PayPalPaymentViewController) {
        print("PayPal Payment Cancelled")
        paymentViewController.dismiss(animated: true, completion: nil)
        
    }
    
    func payPalPaymentViewController(_ paymentViewController: PayPalPaymentViewController, didComplete completedPayment: PayPalPayment) {
        print("PayPal Payment Success !")
        paymentViewController.dismiss(animated: true, completion: { () -> Void in
            print("Here is your proof of payment:")
        })
    }
    
}
