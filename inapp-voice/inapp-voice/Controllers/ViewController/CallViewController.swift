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
    
    @IBOutlet weak var idleCallStackView: UIStackView!
    
    @IBOutlet weak var activeCallStackView: UIStackView!
    
    @IBOutlet weak var callMemberLabel: UILabel!
    
    @IBOutlet weak var callStatusLabel: UILabel!
    
    @IBOutlet weak var ringingStackView: UIStackView!
    
    @IBOutlet weak var hangupButton: UIButton!
    
    @IBOutlet weak var callDataView: UIView!
    
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
        
        // notification
        NotificationCenter.default.addObserver(self, selector: #selector(connectionStatusReceived(_:)), name: .clientStatus, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callReceived(_:)), name: .callStatus, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callHandled), name: .handledCallCallKit, object: nil)
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    func loadMembers() {
        membersManager.fetchMembers(user: user)
    }
    
    @objc func connectionStatusReceived(_ notification: NSNotification) {
        if let clientStatus = notification.object as? VonageClientStatus {
            DispatchQueue.main.async { [weak self] in
   
                if (clientStatus.state == .connected) {
                    self!.showToast(message: "Connected", font: .systemFont(ofSize: 12.0))
                }
                else if (clientStatus.state == .disconnected) {
                    if clientStatus.message != nil {
                        let alert = UIAlertController(title: clientStatus.message, message: nil , preferredStyle: .alert)
                        let alertAction = UIAlertAction(title: "OK", style: .default) { action in
                            self!.dismiss(animated: true)
                        }
                        
                        alert.addAction(alertAction)
                        self!.present(alert, animated: true, completion: nil)
                    }
                    else {
                        self!.showToast(message: "Disconnected", font: .systemFont(ofSize: 12.0))
                        self!.dismiss(animated: true)
                    }
                }
            }
        }
    }
    
    @objc func callReceived(_ notification: NSNotification) {
        DispatchQueue.main.async { [weak self] in
            if let callStatus = notification.object as? CallStatus {
                if (self ==  nil) {return}
                
                switch callStatus.state {
                case .answered, .ringing:
                    self!.displayActiveCall(state: callStatus.state, type: callStatus.type, member: callStatus.member)
                case .completed:
                    self!.displayIdleCall(message: callStatus.message)
                }
            }
        }
        
    }
    
    @objc func callHandled() {
        DispatchQueue.main.async { [weak self] in
            if self?.presentedViewController != nil {
                self?.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func answerCallClicked(_ sender: Any) {
        vgclient.answercall(callId: vgclient.currentCallStatus?.uuid?.toVGCallID()) { isSucess in
            print("answercall state: ", isSucess)
        }
    }
    
    @IBAction func rejectCallClicked(_ sender: Any) {
        vgclient.rejectCall(callId: vgclient.currentCallStatus?.uuid?.toVGCallID())
    }
    
    @IBAction func hangupCallClicked(_ sender: Any) {
        vgclient.hangUpCall(callId: vgclient.currentCallStatus?.uuid?.toVGCallID())
    }
    
    
    
    func displayActiveCall(state: CallState, type: CallType?, member: String?) {
        DispatchQueue.main.async {
            self.idleCallStackView.isHidden = true
            self.activeCallStackView.isHidden = false
            self.callDataView.isHidden = true
            
            if (member != nil) {
                self.callMemberLabel.text = member
            }
            
            if (state == .ringing) {
                self.callStatusLabel.text = "Ringing"
                
            }
            if (state == .answered) {
                self.callStatusLabel.text = "Answered"
                self.callDataView.isHidden = false
            }
            
            if (state == .ringing && type == .inbound) {
                self.ringingStackView.isHidden = false
                self.hangupButton.isHidden = true
            }
            else {
                self.ringingStackView.isHidden = true
                self.hangupButton.isHidden = false
            }
        }
    }
    
    func displayIdleCall(message: String?) {
        DispatchQueue.main.async {
            if (message != nil) {
                let alert = UIAlertController(title: message, message: nil , preferredStyle: .alert)
                let alertAction = UIAlertAction(title: "OK", style: .default) { action in
                    self.idleCallStackView.isHidden = false
                    self.activeCallStackView.isHidden = true
                }
                
                alert.addAction(alertAction)
                self.present(alert, animated: true, completion: nil)
            }
            else {
                self.idleCallStackView.isHidden = false
                self.activeCallStackView.isHidden = true
            }
        }
    }
    
    @IBAction func onLogoutButtonClicked(_ sender: Any) {
        // TODO: logout, delete user
        vgclient.logout()
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
        textField.endEditing(true)
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
