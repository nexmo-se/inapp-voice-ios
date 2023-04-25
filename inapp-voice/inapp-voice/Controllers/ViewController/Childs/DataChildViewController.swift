//
//  DataChildViewController.swift
//  inapp-voice
//
//  Created by iujie on 20/04/2023.
//

import UIKit

class DataChildViewController: UIViewController {

  
    @IBOutlet weak var myLegTitle: UILabel!
    
    @IBOutlet weak var memberLegTitle: UILabel!
    
    @IBOutlet weak var myLegId: UILabel!
    
    @IBOutlet weak var memberLegId: UILabel!
    
    @IBOutlet weak var region: UILabel!
    
    @IBOutlet weak var memberLegStackView: UIStackView!
    
    var callData: CallData?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // notification
        NotificationCenter.default.addObserver(self, selector: #selector(callDataReceived(_:)), name: .callData, object: nil)
        
    }


    @objc func callDataReceived(_ notification: NSNotification) {
        if let callData = notification.object as? CallData {
            DispatchQueue.main.async { [weak self] in
                if self == nil {return}
                
                self!.callData = callData
                
                self!.myLegTitle.text = "my LegId - \(callData.username)"
                self!.myLegId.text = callData.myLegId
                self!.region.text = callData.region
                self!.memberLegTitle.text = "member LegId - \(callData.memberName)"
                
                if (callData.memberLegId != nil) {
                    self!.memberLegId.text = callData.memberLegId
                    self!.memberLegStackView.isHidden = false
                }
                else {
                    self!.memberLegStackView.isHidden = true
                }
            }
        }
    }

    @IBAction func copyButtonClicked(_ sender: Any) {
        if let callData = callData {
            let copiedString = " myLegId - \(callData.username) : \(callData.myLegId), memberLegId - \(callData.memberName) : \(String(describing: callData.memberLegId)), region: \( callData.region)"
            UIPasteboard.general.string = copiedString
            
            // show toast
            self.showToast(message: "Copied", font: .systemFont(ofSize: 12.0))
        }
    }
    
}
