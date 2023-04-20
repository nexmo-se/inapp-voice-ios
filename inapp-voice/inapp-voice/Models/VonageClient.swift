//
//  VonageClient.swift
//  inapp-voice
//
//  Created by iujie on 20/04/2023.
//

import Foundation
import VonageClientSDKVoice



class VonageClient: NSObject {
    var client:VGVoiceClient
    var connectionStatus = ""

    override init(){
        let vonageClient = VGVoiceClient()
        vonageClient.setConfig(.init(region: .US))
        VGBaseClient.setDefaultLoggingLevel(.debug)
        self.client  = vonageClient
        super.init()
    }
    
    func login() {
        if let token = UserModel.user?.token {
            self.client.createSession(token) { error, session in
                if error == nil {
                    self.connectionStatus = "Connected"
                } else {
                    // TODO: show alert here
                    print("vonage login error", error!.localizedDescription)
                }
            }
        }
        

    }
}
