//
//  VonageClient.swift
//  inapp-voice
//
//  Created by iujie on 20/04/2023.
//

import Foundation
import VonageClientSDKVoice
import CallKit
import PushKit
import UserNotifications
import UIKit

enum VonageClientState {
    case connected
    case disconnected
}

enum CallState {
    case ringing
    case answered
    case completed
}

enum CallType {
    case inbound
    case outbound
}

struct VonageClientStatus {
    let state: VonageClientState
    let message: String?
}

struct CallStatus {
    let state: CallState
    let type: CallType?
    let member: String?
    let message: String?

}

struct PushInfo: Codable {
    let voip: Data
    let user: Data
}


class VonageClient: NSObject {
    let voiceClient:VGVoiceClient
    var callId: String?
    var user: UserModel
    var memberName: String?
    
    init(user: UserModel){
        self.user = user
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
        self.voiceClient.createSession(user.token) { error, session in
            if error == nil {
                NotificationCenter.default.post(name: .clientStatus, object: VonageClientStatus(state: .connected, message: nil))

                if (PushToken.voip != nil && PushToken.user != nil) {
                    self.registerPushTokens()
                }

            } else {
                NotificationCenter.default.post(name: .clientStatus, object: VonageClientStatus(state: .disconnected, message: error!.localizedDescription))
            }
        }
    }
    
    func logout() {
        self.voiceClient.deleteSession { error in
            if error != nil {
                NotificationCenter.default.post(name: .clientStatus, object: VonageClientStatus(state: .disconnected, message: error!.localizedDescription))
            }
            else {
                NotificationCenter.default.post(name: .clientStatus, object: VonageClientStatus(state: .disconnected, message: nil))
            }
        }
    }
    
    
    func startOutboundCall(member: String) {
        voiceClient.serverCall(["to": member]) { error, callId in
            if error != nil {
                NotificationCenter.default.post(name:.callStatus, object: CallStatus(state: .completed, type: nil, member: nil, message: error!.localizedDescription))
            } else {
                self.memberName = member
                self.callId = callId
                NotificationCenter.default.post(name:.callStatus, object: CallStatus(state: .ringing, type: .outbound, member: member, message: nil))
            }
        }
    }
    
    func invalidatePushToken() {
        UserDefaults.standard.removeObject(forKey: UserDefaultKeys.vonagePushKey)
    }
    
    func registerPushTokens() {
        if shouldRegisterToken() {
            self.voiceClient.registerDevicePushToken(PushToken.voip, userNotificationToken: PushToken.user, isSandbox: true) { error, device in
                if (error != nil) {
                    print("register push token error: ", error!.localizedDescription)
                }
                print("register token successfully")
                
                let pushInfo = PushInfo(voip: PushToken.voip!, user: PushToken.user!)
                do {
                    // Create JSON Encoder
                    let encoder = JSONEncoder()

                    // Encode Note
                    let data = try encoder.encode(pushInfo)

                    // Write/Set Data
                    UserDefaults.standard.set(data, forKey:  UserDefaultKeys.vonagePushKey)

                } catch {
                    // TODO: alert
                    print("Unable to Encode Note (\(error))")
                }
            }
        }
        
        // Add Observer
        NotificationCenter.default.addObserver(self, selector: #selector(reportVoipPush(_:)), name: .handledPush, object: nil)
    }
    
    private func shouldRegisterToken() -> Bool {
        // Read/Get Data
        if let data = UserDefaults.standard.data(forKey: UserDefaultKeys.vonagePushKey) {
            do {
                // Create JSON Decoder
                let decoder = JSONDecoder()
                
                // Decode Note
                let pushInfo = try decoder.decode(PushInfo.self, from: data)
                
                if pushInfo.voip == PushToken.voip && pushInfo.user == PushToken.user {
                    print("dont register")
                    return false
                }
                else {
                    invalidatePushToken()
                    print("dont register")
                    return true
                }
                
            } catch {
                print("Unable to Decode PushInfo (\(error))")
                invalidatePushToken()
                print("register")
                return true
            }
        }
        else {
            invalidatePushToken()
            print("register")
            return true
        }
    }
    
    func hangUpCall() {
        if (callId == nil) {
            return
        }
        voiceClient.hangup(callId!) { error in
            NotificationCenter.default.post(name:.callStatus, object: CallStatus(state: .completed, type: nil, member: nil, message: error?.localizedDescription))
        }
    }
    
    func rejectCall() {
        if (callId == nil) {
            return
        }
        voiceClient.reject(callId!) { error in
            NotificationCenter.default.post(name:.callStatus, object: CallStatus(state: .completed, type: nil, member: nil, message: error?.localizedDescription))
        }
    }
    func answercall() {
        if (callId == nil) {
            return
        }
        voiceClient.answer(callId!) { error in
            if (error != nil) {
                NotificationCenter.default.post(name:.callStatus, object: CallStatus(state: .completed, type: nil, member: nil, message: error?.localizedDescription))
            }
            else {
                
                if let memberName = self.memberName {
                    NotificationCenter.default.post(name: .callData, object: CallData(username: self.user.username, memberName: memberName, myLegId: self.callId!, memberLegId: nil, region: self.user.region))
                }
                
                NotificationCenter.default.post(name:.callStatus, object: CallStatus(state: .answered, type: nil, member: nil, message: nil))
            }
        }
    }
    
    
    @objc private func reportVoipPush(_ notification: NSNotification) {
        print("report voip")
        if let payload = notification.object as? PKPushPayload {
            self.voiceClient.processCallInvitePushData(payload.dictionaryPayload)

        }
    }
}

extension VonageClient: VGVoiceClientDelegate {
    func voiceClient(_ client: VGVoiceClient, didReceiveInviteForCall callId: String, from caller: String, withChannelType type: String) {
        self.callId = callId
        self.memberName = caller
        print("here1 receive call")

        NotificationCenter.default.post(name:.callStatus, object: CallStatus(state: .ringing, type:.inbound, member: caller, message: nil))
    }
    
    func voiceClient(_ client: VGVoiceClient, didReceiveHangupForCall callId: String, withQuality callQuality: VGRTCQuality, isRemote: Bool) {
        self.callId = nil
        print("here1 hangup call")
        if (isRemote) {
            NotificationCenter.default.post(name:.callStatus, object: CallStatus(state: .completed, type: nil, member: nil, message: "User ends the call"))
        }
    }
    
    func voiceClient(_ client: VGVoiceClient, didReceiveInviteCancelForCall callId: String, with reason: VGVoiceInviteCancelReasonType) {
        
        if (callId == self.callId) {
            return
        }
        self.callId = nil
        
        var callEndReason = "Incoming call failed"
        
        switch (reason){
        case .remoteTimeout: callEndReason = "Incoming call unanswered"
        case .remoteReject: callEndReason = "Incoming call declined elsewhere"
        case .remoteAnswer: callEndReason = "Incoming call answered elsewhere"
        case .remoteCancel: callEndReason = "Incoming call remote cancelled"
        @unknown default:
            callEndReason = "Incoming call unknown error"
        }
        
        NotificationCenter.default.post(name:.callStatus, object: CallStatus(state: .completed, type: nil, member: nil, message: callEndReason))
    }
    
    func voiceClient(_ client: VGVoiceClient, didReceiveLegStatusUpdateForCall callId: String, withLegId legId: String, andStatus status: String) {
        // For our one to one calls, we are only really interested in answered legs
        print("here1 status call", status)
        if (status == "answered") {
            self.callId = callId
            
            if let memberName = memberName {
                NotificationCenter.default.post(name: .callData, object: CallData(username: user.username, memberName: memberName, myLegId: callId, memberLegId: legId, region: user.region))
            }

            NotificationCenter.default.post(name:.callStatus, object: CallStatus(state: .answered, type: .inbound, member: nil, message: nil))
        }
    }
    
    func client(_ client: VGBaseClient, didReceiveSessionErrorWith reason: VGSessionErrorReason) {
        let statusText: String
        switch reason {
            case .EXPIRED_TOKEN:
                statusText = "Session Token Expired"
            case .PING_TIMEOUT, .TRANSPORT_CLOSED:
                statusText = "Session Network Error"
            @unknown default:
                statusText = "Session Unknown Error"
        }
        NotificationCenter.default.post(name: .clientStatus, object: statusText)
    }
}
