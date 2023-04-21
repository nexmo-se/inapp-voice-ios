//
//  LoginViewController.swift
//  inapp-voice
//
//  Created by iujie on 19/04/2023.
//

import UIKit

class LoginViewController: UIViewController {

    @IBOutlet weak var usernameTextField: UITextField!
    
    @IBOutlet weak var regionTextField: UITextField!
    
    @IBOutlet weak var pinTextField: UITextField!
    
    @IBOutlet weak var regionTableView: UITableView!
    
    @IBOutlet weak var submitButton: UIButton!
    
    var regionSearchResult = Region.countries
    var credentialManager = CredentialManager()
    var user: UserModel?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        regionTextField.delegate = self
        regionTableView.dataSource = self
        regionTableView.delegate = self
        credentialManager.delegate = self
    }

    @IBAction func submitButtonClicked(_ sender: Any) {
        if ((usernameTextField.text == "") || (regionTextField.text == "") || (pinTextField.text == "")) {
            self.showToast(message: "Missing Sign-In information", font: .systemFont(ofSize: 12.0))
            return
        }
        if !Region.countries.contains(regionTextField.text!) {
            self.showToast(message: "Invalid region", font: .systemFont(ofSize: 12.0))
            return
        }
        submitButton.isEnabled = false
        credentialManager.fetchCredential(username: usernameTextField.text!, region: regionTextField.text!, pin: pinTextField.text!)
    }
    
}


//MARK: UITextFieldDelegate
extension LoginViewController: UITextFieldDelegate {
    func textFieldDidBeginEditing(_ textField: UITextField) {
        regionTableView.isHidden = false
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        regionTableView.isHidden = true
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        regionSearchResult = filterCountries(input: regionTextField.text!)
        regionTableView.reloadData()
        return true
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        regionSearchResult = filterCountries(input: regionTextField.text!)
        regionTableView.reloadData()
    }
    
    func filterCountries(input: String) -> Array<String> {
        if input != "" && !Region.countries.contains(input){
            return Region.countries.filter({ country in
                country.lowercased().contains(input.lowercased())
            })
        }
        else {
            return Region.countries
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

//MARK: CredentialManagerDelegate
extension LoginViewController: CredentialManagerDelegate {
    func didUpdateUser(user: UserModel) {
        self.user = user
        DispatchQueue.main.async {
            self.submitButton.isEnabled = true
            self.performSegue(withIdentifier: "goToCallVC", sender: self)
        }
    }
    func handleCredentialManagerError(message: String) {
        DispatchQueue.main.async {
            self.submitButton.isEnabled = true
            let alert = UIAlertController(title: message, message: nil , preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let vc = segue.destination as? CallViewController {
            vc.user = user
        }
    }
    
}
