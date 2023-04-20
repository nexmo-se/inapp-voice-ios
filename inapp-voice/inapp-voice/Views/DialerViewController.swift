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
        print("in dialer")
        // Do any additional setup after loading the view.
    }
    

    @IBAction func callButtonClicked(_ sender: Any) {
    }
    
    @IBAction func logoutButtonClicked(_ sender: Any) {
        // Clear user data
        UserModel.user = nil
        dismiss(animated: true)
    }
    
}
