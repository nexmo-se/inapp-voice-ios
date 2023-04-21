//
//  NetworkManager.swift
//  inapp-voice
//
//  Created by iujie on 19/04/2023.
//

import Foundation

protocol CredentialManagerDelegate {
    func didUpdateUser(user: UserModel)
    func handleCredentialManagerError(message: String)
}

struct CredentialManager {    
    var delegate: CredentialManagerDelegate?
    
    func fetchCredential(username:String, region: String, pin: String) {
              
        let parameters: [String: String] = [
            "username": username,
            "region": region,
            "pin": pin
        ]
        
        if let url = URL(string: "\(Network.backendURL)/getCredential") {
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            request.addValue("application/json", forHTTPHeaderField: "Content-Type") // change as per server requirements
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
  
            do {
              // convert parameters to Data and assign dictionary to httpBody of request
              request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch let error {
                self.delegate?.handleCredentialManagerError(message: error.localizedDescription)
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {
                    self.delegate?.handleCredentialManagerError(message: error!.localizedDescription)
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if (httpResponse.statusCode != 200) {
                        self.delegate?.handleCredentialManagerError(message: "Failed to get token")
                        return
                    }
                }
                if let safeData = data {
                    if let user = self.parseJSON(credentialData: safeData) {
                        self.delegate?.didUpdateUser(user: user)
                    }
                    else {
                        self.delegate?.handleCredentialManagerError(message: "Failed to parse credential data")
                    }
                }
            }.resume()
        }
    }

    
    func parseJSON(credentialData: Data) -> UserModel?{
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(UserModel.self, from: credentialData)
            return decodedData
        } catch {
            print("parse json error: ", error)
            return nil
        }
    }
}
