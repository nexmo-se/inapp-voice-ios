//
//  NetworkManager.swift
//  inapp-voice
//
//  Created by iujie on 19/04/2023.
//

import Foundation

protocol CredentialManagerDelegate {
    func didUpdateUser(user: UserData)
}

struct CredentialManager {
    let backendURL = "https://6211-2001-e68-5432-24d3-4dc9-bfa5-19f5-7da1.ngrok-free.app"
    
    var delegate: CredentialManagerDelegate?
    
    func fetchCredential(username:String, region: String, pin: String) {
              
        let parameters: [String: String] = [
            "username": username,
            "region": region,
            "pin": pin
        ]
        
        if let url = URL(string: "\(backendURL)/register") {
            
            var request = URLRequest(url: url)
            request.httpMethod = "POST"

            request.addValue("application/json", forHTTPHeaderField: "Content-Type") // change as per server requirements
            request.addValue("application/json", forHTTPHeaderField: "Accept")
            
  
            do {
              // convert parameters to Data and assign dictionary to httpBody of request
              request.httpBody = try JSONSerialization.data(withJSONObject: parameters, options: .prettyPrinted)
            } catch let error {
                print("json serialization error", error.localizedDescription)
                return
            }
            
            URLSession.shared.dataTask(with: request) { data, response, error in
                if error != nil {
                    //TODO: show alert
                    print("handle response error: ", error!)
                    return
                }
                if let httpResponse = response as? HTTPURLResponse {
                    if (httpResponse.statusCode != 200) {
                        self.delegate?.didUpdateUser(user: UserData(username: "", token: "", region: "", error: "Failed to get token"))
                        return
                    }
                }
                if let safeData = data {
                    if let user = self.parseJSON(credentialData: safeData) {
                        UserModel.user = user
                        self.delegate?.didUpdateUser(user: user)
                    }
                }
            }.resume()
        }
    }

    
    func parseJSON(credentialData: Data) -> UserData?{
        let decoder = JSONDecoder()
        do {
            let decodedData = try decoder.decode(UserData.self, from: credentialData)
            return decodedData
        } catch {
            // TODO: alert error
            print("parse json error: ", error)
            return nil
        }
    }
}
