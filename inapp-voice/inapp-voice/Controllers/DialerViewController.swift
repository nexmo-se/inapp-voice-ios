//
//  DialerViewController.swift
//  inapp-voice
//
//  Created by iujie on 19/04/2023.
//

import UIKit

class DialerViewController: UIViewController {

    @IBOutlet weak var usernameRegionLabel: UILabel!
    
    @IBOutlet weak var callUserTextField: UITextField!

    override func viewDidLoad() {
        super.viewDidLoad()
       
        loadMembers()
        if UserModel.user != nil {
            login()
        }
        else {
            self.showToast(message: "Vonage login Failed", font: .systemFont(ofSize: 12.0))
            dismiss(animated: true)
        }
        
    }
    
    func loadMembers() {
        
    }
    
    func login() {
        if UserModel.user != nil {
            
        }
    }

    @IBAction func callButtonClicked(_ sender: Any) {
    }
    
    @IBAction func logoutButtonClicked(_ sender: Any) {
        // Clear user data
        UserModel.user = nil
        dismiss(animated: true)
    }
    
}
