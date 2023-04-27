//
//  LoginViewController.swift
//  inapp-voice
//
//  Created by iujie on 19/04/2023.
//

import UIKit

class LoginViewController: UIViewController {
    
    // Form
    @IBOutlet weak var formStackView: UIStackView!
    @IBOutlet weak var usernameTextField: UITextField!
    @IBOutlet weak var regionTextField: UITextField!
    @IBOutlet weak var pinTextField: UITextField!
    @IBOutlet weak var submitButton: UIButton!
    
    // Table
    @IBOutlet weak var regionTableView: UITableView!
    
    var regionSearchResult = Constants.countries
    
    var user: UserModel?
    var userManager = UserManager()
    
    let inputTag: [String: Int] = [
        "username": 1,
        "region": 2,
        "pin": 3
    ]
    
    let loadingActivityIndicator = createLoadingActivityIndicator()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        userManager.delegate = self
        
        usernameTextField.tag = inputTag["username"]!
        usernameTextField.delegate = self
        
        regionTextField.tag = inputTag["region"]!
        regionTextField.delegate = self
        
        pinTextField.tag = inputTag["pin"]!
        pinTextField.delegate = self
        
        regionTableView.dataSource = self
        regionTableView.delegate = self
        
        
        // If user logged in
        if let data = UserDefaults.standard.data(forKey: Constants.userKey) {
            do {
                let decoder = JSONDecoder()
                let user = try decoder.decode(UserModel.self, from: data)
                
                // Refresh token
                userManager.fetchCredential(username: user.username, region: user.region, pin: nil, token: user.token)
                
                formStackView.isHidden = true
                
                // Add loading spinner
                loadingActivityIndicator.center = CGPoint(
                    x: view.bounds.midX,
                    y: view.bounds.midY
                )
                view.addSubview(loadingActivityIndicator)
            } catch {
                self.present(createAlert(message: "Unable to Decode user: \(error)", completion: { isActionSubmitted in
                    self.formStackView.isHidden = false
                }), animated: true)
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        formStackView.isHidden = false
        loadingActivityIndicator.removeFromSuperview()
    }
    
    
    @IBAction func submitButtonClicked(_ sender: Any) {
        if ((usernameTextField.text == "") || (regionTextField.text == "") || (pinTextField.text == "")) {
            self.showToast(message: "Missing Sign-In information", font: .systemFont(ofSize: 12.0))
            return
        }
        if !Constants.countries.contains(regionTextField.text!) {
            self.showToast(message: "Invalid region", font: .systemFont(ofSize: 12.0))
            return
        }
        submitButton.isEnabled = false
        userManager.fetchCredential(username: usernameTextField.text!, region: regionTextField.text!, pin: pinTextField.text!, token: nil)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CallViewController {
            vc.user = user
        }
    }
    
}


//MARK: UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        if (textField.tag == inputTag["region"]) {
            regionTableView.isHidden = false
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (textField.tag == inputTag["region"]) {
            regionTableView.isHidden = true
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.tag == inputTag["region"]) {
            regionSearchResult = filterCountries(input: regionTextField.text!)
            regionTableView.reloadData()
        }
        textField.endEditing(true)
        return true
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if (textField.tag == inputTag["region"]) {
            regionSearchResult = filterCountries(input: regionTextField.text!)
            regionTableView.reloadData()
        }
    }
    
    func filterCountries(input: String) -> Array<String> {
        if input != "" && !Constants.countries.contains(input){
            return Constants.countries.filter({ country in
                country.lowercased().contains(input.lowercased())
            })
        }
        else {
            return Constants.countries
        }
    }
}

//MARK: UITableViewDataSource
extension LoginViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "regionTableCell")
        
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "regionTableCell")
        }
        
        var config = UIListContentConfiguration.cell()
        config.text = regionSearchResult[indexPath.row]
        cell?.contentConfiguration = config
        
        return cell!
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return regionSearchResult.count
    }
}

//MARK: UITableViewDelegate
extension LoginViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        regionTextField.text = regionSearchResult[indexPath.row]
        regionTextField.endEditing(true)
    }
}

//MARK: UserManagerDelegate
extension LoginViewController: UserManagerDelegate {
    func didUpdateUser(user: UserModel) {
        self.user = user
        DispatchQueue.main.async { [weak self] in
            if (self == nil) {return}
            
            self!.submitButton.isEnabled = true
            self!.performSegue(withIdentifier: "goToCallVC", sender: self)
        }
    }
    func handleUserManagerError(message: String) {
        DispatchQueue.main.async { [weak self] in
            if (self == nil) {return}
            
            self!.formStackView.isHidden = false
            self!.loadingActivityIndicator.removeFromSuperview()
            self!.submitButton.isEnabled = true
            self!.present(createAlert(message: message, completion: nil), animated: true, completion: nil)
        }
    }
}
