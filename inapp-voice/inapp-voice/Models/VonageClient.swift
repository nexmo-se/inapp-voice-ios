//
//  VonageClient.swift
//  inapp-voice
//
//  Created by iujie on 20/04/2023.
//

import Foundation
import VonageClientSDKVoice
import CallKit


enum CallStatus {
    case ringing(member: String)
    case answered
    case completed(remote:Bool, reason: CXCallEndedReason?)
}

struct CallUpdate {
    let callId: String
    let legId: String
    let status: CallStatus
}

protocol VonageClientDelegate {
    func didConnectionStatusUpdated(status: String)
    func handleVonageClientError(message: String, forceDismiss: Bool)
    func didCallStatusUpdate(call: CallStatus)
}

class VonageClient: NSObject {
    var voiceClient:VGVoiceClient
    var delegate: VonageClientDelegate?

    init(user: UserModel){
        let vonageClient = VGVoiceClient()
        let config = VGClientConfig()
        config.apiUrl = user.dc
        config.websocketUrl = user.ws
        vonageClient.setConfig(config)
        VGBaseClient.setDefaultLoggingLevel(.debug)
        self.voiceClient  = vonageClient
        
        super.init()
        self.voiceClient.delegate = self
    }
    
    func login(user: UserModel) {
        print("user token", user.token)
        self.voiceClient.createSession(user.token) { error, session in
            if error == nil {
                self.delegate?.didConnectionStatusUpdated(status: "Connected")
            } else {
                print("error here")
                self.delegate?.handleVonageClientError(message: error!.localizedDescription, forceDismiss: true)
            }
        }
    }
    
    func startOutboundCall(member: String) {
        print("member ", member)
        voiceClient.serverCall(["to": member]) { error, callId in
            if error != nil {
                self.delegate?.handleVonageClientError(message: error!.localizedDescription, forceDismiss: false)
            } else {
                self.delegate?.didCallStatusUpdate(call: CallStatus.ringing(member: member))
               
            }
        }
    }
}

extension VonageClient: VGVoiceClientDelegate {
    func voiceClient(_ client: VGVoiceClient, didReceiveInviteForCall callId: String, from caller: String, withChannelType type: String) {
        self.delegate?.didCallStatusUpdate(call: CallStatus.ringing(member: caller))
    }
    
    func voiceClient(_ client: VGVoiceClient, didReceiveHangupForCall callId: String, withQuality callQuality: VGRTCQuality, isRemote: Bool) {
        if (isRemote) {
            self.delegate?.didCallStatusUpdate(call: CallStatus.completed(remote: true, reason: .remoteEnded))
        }
        else {
            self.delegate?.didCallStatusUpdate(call: CallStatus.completed(remote: false, reason: nil))

        }
       
    }
    
    func voiceClient(_ client: VGVoiceClient, didReceiveInviteCancelForCall callId: String, with reason: VGVoiceInviteCancelReasonType) {
        var cxreason: CXCallEndedReason = .failed
        
        switch (reason){
        case .remoteTimeout: cxreason = .unanswered
        case .remoteReject: cxreason = .declinedElsewhere
        case .remoteAnswer: cxreason = .answeredElsewhere
        case .remoteCancel: cxreason = .remoteEnded
        @unknown default:
            self.delegate?.handleVonageClientError(message: "Call Unknown Error", forceDismiss: false)
        }
        self.delegate?.didCallStatusUpdate(call: CallStatus.completed(remote: true, reason: cxreason))
    }
    
    func voiceClient(_ client: VGVoiceClient, didReceiveLegStatusUpdateForCall callId: String, withLegId legId: String, andStatus status: String) {
        // For our one to one calls, we are only really interested in answered legs
        if (status == "answered") {
            self.delegate?.didCallStatusUpdate(call: CallStatus.answered)
        }
      }
    
    func client(_ client: VGBaseClient, didReceiveSessionErrorWith reason: VGSessionErrorReason) {
        switch reason {
            case .EXPIRED_TOKEN:
                self.delegate?.handleVonageClientError(message: "Client Token Expired", forceDismiss: true)
            case .PING_TIMEOUT, .TRANSPORT_CLOSED:
                self.delegate?.handleVonageClientError(message: "Client Network Error", forceDismiss: true)
            @unknown default:
                self.delegate?.handleVonageClientError(message: "Client Unknown Error", forceDismiss: true)
        }
    }
    
    
}
