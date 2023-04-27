//
//  DialerViewController.swift
//  inapp-voice
//
//  Created by iujie on 19/04/2023.
//

import UIKit

class CallViewController: UIViewController {
    
    // Idle Call View
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var idleCallStackView: UIStackView!
    @IBOutlet weak var callButton: UIButton!
    @IBOutlet weak var memberSearchTextField: UITextField!
    @IBOutlet weak var memberTableView: UITableView!
    @IBOutlet weak var logoutButton: UIButton!
    
    // Active Call View
    @IBOutlet weak var activeCallStackView: UIStackView!
    @IBOutlet weak var callMemberLabel: UILabel!
    @IBOutlet weak var callStatusLabel: UILabel!
    @IBOutlet weak var ringingStackView: UIStackView!
    @IBOutlet weak var answerButton: UIButton!
    @IBOutlet weak var rejectButton: UIButton!
    @IBOutlet weak var hangupButton: UIButton!
    
    // Call Data
    @IBOutlet weak var callDataView: UIView!
    
    var user: UserModel!
    var userManager = UserManager()
    var vgclient: VonageClient!
    
    var memberList: MemberModel!
    var membersManager = MembersManager()
    var memberSearchResult = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if (user == nil) {
            self.present(createAlert(message: "Missing user", completion: { isActionSubmitted in
                self.dismiss(animated: true)
            }), animated: true, completion: nil)
            return
        }

        // VoiceClient login
        vgclient = VonageClient(user: user)
        vgclient.login(user: user)
        
        
        // Initial View - title
        usernameLabel.text = "\(user.username) (\(user.region))"
        
        // Initial View - Action Button
        callButton.isEnabled = false
        callDataView.layer.borderWidth = 2
        callDataView.layer.borderColor = .init(red: 196/255, green: 53/255, blue: 152/255, alpha: 1)
        
        // Initial View - Members
        memberSearchTextField.delegate = self
        memberTableView.dataSource = self
        memberTableView.delegate = self
        membersManager.delegate = self
        loadMembers()
        
        // notification
        NotificationCenter.default.addObserver(self, selector: #selector(connectionStatusReceived(_:)), name: .clientStatus, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callReceived(_:)), name: .callStatus, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    private func loadMembers() {
        membersManager.fetchMembers(user: user)
    }
    
    private func displayActiveCall(state: CallState, type: CallType?, member: String?) {
        DispatchQueue.main.async { [weak self] in
            if (self == nil) {return}
            
            self!.logoutButton.isHidden = true
            self!.idleCallStackView.isHidden = true
            self!.activeCallStackView.isHidden = false
            
            self!.ringingStackView.isHidden = true
            self!.hangupButton.isHidden = false
            
            if (member != nil) {
                self!.callMemberLabel.text = member
            }
            
            if (state == .ringing) {
                self!.callStatusLabel.text = "Ringing"
                self!.callDataView.isHidden = true
                
                if (type == .inbound) {
                    self!.ringingStackView.isHidden = false
                    self!.hangupButton.isHidden = true
                }
                
            }
            if (state == .answered) {
                self!.callStatusLabel.text = "Answered"
                self!.callDataView.isHidden = false
            }
        }
    }
    
    func displayIdleCall(message: String?) {
        DispatchQueue.main.async { [weak self] in
            if (self == nil) {return}
            
            self!.logoutButton.isHidden = false
            if (message != nil) {
                self!.present(createAlert(message: message!, completion: { isActionSubmitted in
                    self!.idleCallStackView.isHidden = false
                    self!.activeCallStackView.isHidden = true
                }), animated: true, completion: nil)
            }
            else {
                self!.idleCallStackView.isHidden = false
                self!.activeCallStackView.isHidden = true
            }
        }
    }
    
    func disableActionButtons() {
        hangupButton.isEnabled = false
        answerButton.isEnabled = false
        rejectButton.isEnabled = false
        callButton.isEnabled = false
    }
    
    func enableActionButton() {
        hangupButton.isEnabled = true
        answerButton.isEnabled = true
        rejectButton.isEnabled = true
        callButton.isEnabled = true
    }
}

//MARK: Notifications
extension CallViewController {
    @objc func connectionStatusReceived(_ notification: NSNotification) {
        if let clientStatus = notification.object as? VonageClientStatusModel {
            DispatchQueue.main.async { [weak self] in
                if (self == nil) {return}
                
                if (clientStatus.state == .connected) {
                    self!.showToast(message: "Connected", font: .systemFont(ofSize: 12.0))
                    
                    // store user to userdefault
                    do {
                        let encoder = JSONEncoder()
                        
                        let data = try encoder.encode(self!.user)
                        
                        UserDefaults.standard.set(data, forKey: Constants.userKey)
                        
                    } catch {
                        self!.showToast(message: "Unable to encode user", font: .systemFont(ofSize: 12.0))
                    }
                }
                else if (clientStatus.state == .disconnected) {
                    UserDefaults.standard.removeObject(forKey: Constants.userKey)
                    
                    self!.userManager.deleteUser(user: self!.user)
                   
                    if clientStatus.message != nil {
                        self!.present(createAlert(message: clientStatus.message!, completion: { isActionSubmitted in
                            self!.showToast(message: "Disconnected", font: .systemFont(ofSize: 12.0))
                            self!.dismiss(animated: true)
                        }), animated: true, completion: nil)
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
            if let callStatus = notification.object as? CallStatusModel {
                if (self ==  nil) {return}
                self!.enableActionButton()
                
                switch callStatus.state {
                case .answered, .ringing:
                    self!.displayActiveCall(state: callStatus.state, type: callStatus.type, member: callStatus.member)
                case .completed:
                    self!.displayIdleCall(message: callStatus.message)
                }
            }
        }
        
    }
}

//MARK: Actions
extension CallViewController {
    @IBAction func onCallbuttonClicked(_ sender: Any) {
        disableActionButtons()
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
    
    @IBAction func answerCallClicked(_ sender: Any) {
        disableActionButtons()
        vgclient.answerByCallkit(calluuid: vgclient.currentCallStatus?.uuid)
    }
    
    @IBAction func rejectCallClicked(_ sender: Any) {
        disableActionButtons()
        vgclient.rejectByCallkit(calluuid: vgclient.currentCallStatus?.uuid)
    }
    
    @IBAction func hangupCallClicked(_ sender: Any) {
        disableActionButtons()
        vgclient.hangUpCall(callId: vgclient.currentCallStatus?.uuid?.toVGCallID())
    }
    
    @IBAction func onLogoutButtonClicked(_ sender: Any) {
        vgclient.logout()
    }
}

//MARK: MembersManagerDelegate
extension CallViewController: MembersManagerDelegate {
    func didUpdateMembers(memberList: MemberModel) {
        DispatchQueue.main.async { [weak self] in
            if (self == nil) {return}
            
            self!.memberList = memberList
            self!.memberSearchResult = memberList.members
            self!.memberTableView.reloadData()
        }
    }
    
    func handleMembersManagerError(message: String) {
        DispatchQueue.main.async { [weak self] in
            if (self == nil) {return}
            
            let alert = createAlert(message: message) { isActionSubmitted in
                if (isActionSubmitted) {
                    self!.dismiss(animated: true, completion: nil)
                }
            }
            self!.present(alert, animated: true, completion: nil)
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