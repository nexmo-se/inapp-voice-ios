//
//  VonageClient.swift
//  inapp-voice
//
//  Created by iujie on 20/04/2023.
//

import Foundation
import VonageClientSDKVoice


protocol VonageClientDelegate {
    func didConnectionStatusUpdated(status: String)
    func handleVonageClientError(message: String)
}

class VonageClient: NSObject {
    var voiceClient:VGVoiceClient
    var connectionStatus = ""
    var delegate: VonageClientDelegate?

    init(dc: String){
        let vonageClient = VGVoiceClient()
        let config = VGClientConfig()
        config.apiUrl = dc
        vonageClient.setConfig(config)
        VGBaseClient.setDefaultLoggingLevel(.debug)
        self.voiceClient  = vonageClient
    }
    
    func login(user: UserModel) {
        self.voiceClient.createSession(user.token) { error, session in
            if error == nil {
                self.connectionStatus = "Connected"
                self.delegate?.didConnectionStatusUpdated(status: "Connected")
            } else {
                self.delegate?.handleVonageClientError(message: error!.localizedDescription)
            }
        }
        
    }
}
