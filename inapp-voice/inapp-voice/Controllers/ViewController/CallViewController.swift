//
//  DialerViewController.swift
//  inapp-voice
//
//  Created by iujie on 19/04/2023.
//

import UIKit

class CallViewController: UIViewController {
    
    @IBOutlet weak var callButton: UIButton!
    
    @IBOutlet weak var usernameLabel: UILabel!
    
    @IBOutlet weak var memberSearchTextField: UITextField!
    
    @IBOutlet weak var memberTableView: UITableView!
    
    
    var user: UserModel!
    var memberList: MemberModel!
    var vgclient: VonageClient!
    var membersManager = MembersManager()
    var memberSearchResult = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
       
        if (user == nil) {
            self.showToast(message: "Missing user", font: .systemFont(ofSize: 12.0))
            dismiss(animated: true)
            return
        }
        
        callButton.isEnabled = false
        
        // vonage client
        vgclient = VonageClient(user: user)
        vgclient.delegate = self
        vgclient.login(user: user)
        
        // diplay title
        usernameLabel.text = "\(user.username) (\(user.region))"
        
        // members
        membersManager.delegate = self
        loadMembers()
        
        // membertableview
        memberSearchTextField.delegate = self
        memberTableView.dataSource = self
        memberTableView.delegate = self
        
        
    }
    
    func loadMembers() {
        membersManager.fetchMembers(user: user)
    }
    
    
    @IBAction func onLogoutButtonClicked(_ sender: Any) {
        // TODO: logout, delete user
        self.dismiss(animated: true)
    }
    
    @IBAction func onCallbuttonClicked(_ sender: Any) {
        if (memberSearchTextField.text == "") {
            self.showToast(message: "Please select a member", font: .systemFont(ofSize: 12.0))
            return
        }
        let member = memberSearchTextField.text!
        if (!memberList.members.contains(member)) {
            self.showToast(message: "Invalid member", font: .systemFont(ofSize: 12.0))
            return
        }
        vgclient.startOutboundCall(member: member)
    }
}

//MARK: VonageClientDelegate
extension CallViewController: VonageClientDelegate {
    func didCallStatusUpdate(call: CallStatus) {
        print("did call Status update", call)
    }
    
    func didConnectionStatusUpdated(status: String) {
        DispatchQueue.main.async {
            self.showToast(message: "connected", font: .systemFont(ofSize: 12.0))
        }
    }
    
    func handleVonageClientError(message: String, forceDismiss: Bool) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: message, message: nil , preferredStyle: .alert)
            var alertAction = UIAlertAction(title: "OK", style: .default)
            if forceDismiss {
                alertAction = UIAlertAction(title: "OK", style: .default) { action in
                    self.dismiss(animated: true)
                }
            }
            
            alert.addAction(alertAction)
            self.present(alert, animated: true, completion: nil)
            
        }
    }
}

//MARK: CallViewControllerDelegate
extension CallViewController: MembersManagerDelegate {
    func didUpdateMembers(memberList: MemberModel) {
        DispatchQueue.main.async {
            self.memberList = memberList
            self.memberSearchResult = memberList.members
            self.memberTableView.reloadData()
        }
    }
    
    func handleMembersManagerError(message: String) {
        DispatchQueue.main.async {
            let alert = UIAlertController(title: message, message: nil , preferredStyle: .alert)
            let okAction = UIAlertAction(title: "OK", style: .default) {
                UIAlertAction in
                self.dismiss(animated: true, completion: nil)
            }
            
            alert.addAction(okAction)
            self.present(alert, animated: true, completion: nil)
        }
    }
}

//MARK: UITextFieldDelegate
extension CallViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        memberTableView.isHidden = false
        loadMembers()
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        memberTableView.isHidden = true
        callButton.isEnabled = true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        memberSearchResult = filterMembers(input: memberSearchTextField.text!)
        memberTableView.reloadData()
        return true
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        memberSearchResult = filterMembers(input: memberSearchTextField.text!)
        memberTableView.reloadData()
    }
    
    func filterMembers(input: String) -> Array<String> {
        if input != "" && !memberList.members.contains(input){
            return memberList.members.filter({ member in
                member.lowercased().contains(input.lowercased())
            })
        }
        else {
            return memberList.members
        }
    }
}

//MARK: UITableViewDataSource
extension CallViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "memberTableCell")
        
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "memberTableCell")
        }
        
        var config = UIListContentConfiguration.cell()
        config.text = memberSearchResult[indexPath.row]
        cell?.contentConfiguration = config
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return memberSearchResult.count
    }
}

//MARK: UITableViewDelegate
extension CallViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        memberSearchTextField.text = memberSearchResult[indexPath.row]
        memberSearchTextField.endEditing(true)
    }
}
