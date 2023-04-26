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
    
    @IBOutlet weak var formStackView: UIStackView!
    
    let usernameTag = 1
    let regionTag = 2
    let pinTag = 3
    
    var regionSearchResult = Region.countries
    var userManager = UserManager()
    var user: UserModel?
    
    var loadingActivityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView()
        
        indicator.style = .large
        indicator.color = .darkGray
            
        // The indicator should be animating when
        // the view appears.
        indicator.startAnimating()
            
        // Setting the autoresizing mask to flexible for all
        // directions will keep the indicator in the center
        // of the view and properly handle rotation.
        indicator.autoresizingMask = [
            .flexibleLeftMargin, .flexibleRightMargin,
            .flexibleTopMargin, .flexibleBottomMargin
        ]
            
        return indicator
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        usernameTextField.tag = usernameTag
        usernameTextField.delegate = self
        
        regionTextField.tag = regionTag
        regionTextField.delegate = self
        
        pinTextField.tag = pinTag
        pinTextField.delegate = self
        
        regionTableView.dataSource = self
        regionTableView.delegate = self
        userManager.delegate = self
        
        
        // Read/Get Data
        if let data = UserDefaults.standard.data(forKey: UserDefaultKeys.userKey) {
            do {
                // Create JSON Decoder
                let decoder = JSONDecoder()

                let user = try decoder.decode(UserModel.self, from: data)
                // Refresh token
                userManager.fetchCredential(username: user.username, region: user.region, pin: nil, token: user.token)
                
                formStackView.isHidden = true
                
                // center of view
                loadingActivityIndicator.center = CGPoint(
                    x: view.bounds.midX,
                    y: view.bounds.midY
                )
                view.addSubview(loadingActivityIndicator)
            } catch {
                print("Unable to Decode user (\(error))")
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
        if !Region.countries.contains(regionTextField.text!) {
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
        if (textField.tag == regionTag) {
            regionTableView.isHidden = false
        }
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        if (textField.tag == regionTag) {
            regionTableView.isHidden = true
        }
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if (textField.tag == regionTag) {
            regionSearchResult = filterCountries(input: regionTextField.text!)
            regionTableView.reloadData()
        }
        textField.endEditing(true)
        return true
    }
    func textFieldDidChangeSelection(_ textField: UITextField) {
        if (textField.tag == regionTag) {
            regionSearchResult = filterCountries(input: regionTextField.text!)
            regionTableView.reloadData()
        }
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

//MARK: UserManagerDelegate
extension LoginViewController: UserManagerDelegate {
    func didUpdateUser(user: UserModel) {
        self.user = user
        DispatchQueue.main.async {
            self.submitButton.isEnabled = true
            self.performSegue(withIdentifier: "goToCallVC", sender: self)
        }
    }
    func handleUserManagerError(message: String) {
        DispatchQueue.main.async {
            self.submitButton.isEnabled = true
            let alert = UIAlertController(title: message, message: nil , preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)
        }
    }
}
