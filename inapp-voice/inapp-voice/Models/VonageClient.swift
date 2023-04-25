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
    case completed(remote:Bool, reason:CXCallEndedReason?)
}
extension CallState: Equatable {}

enum CallType {
    case inbound
    case outbound
}

struct VonageClientStatus {
    let state: VonageClientState
    let message: String?
}

struct CallStatus {
    let uuid: UUID?
    let state: CallState
    let type: CallType
    let member: String?
    let message: String?

}

struct PushInfo: Codable {
    let voip: Data
    let user: Data
}


class VonageClient: NSObject {
    let voiceClient:VGVoiceClient
    var user: UserModel
    var memberName: String?
    var currentCallStatus: CallStatus? {
        didSet {
            if (currentCallStatus != nil) {
                NotificationCenter.default.post(name:.callStatus, object: currentCallStatus)
                updateCallKit(call: currentCallStatus!)
            }
        }
    }
    
    // Callkit
    lazy var callProvider = { () -> CXProvider in
        var config = CXProviderConfiguration()
        config.supportsVideo = false
        let provider = CXProvider(configuration: config)
        provider.setDelegate(self, queue: nil)
        return provider
    }()
    
    lazy var cxController = CXCallController()
    
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
                self.currentCallStatus = CallStatus(uuid: nil, state: .completed(remote: false, reason: .failed), type: .outbound, member: nil, message: error!.localizedDescription)
            } else {
                
                if let callId = callId {
                    self.memberName = member
                    self.currentCallStatus = CallStatus(uuid: UUID(uuidString: callId)!, state: .ringing, type: .outbound, member: member, message: nil)
                }
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
    
    deinit {
        NotificationCenter.default.removeObserver(self)
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
    
    func hangUpCall(callId: String?) {
        print("hang up called", self.currentCallStatus!.type)
        if let callId = callId {
            voiceClient.hangup(callId) { error in
                self.currentCallStatus = CallStatus(uuid: UUID(uuidString: callId)!, state: .completed(remote: false, reason: nil), type: self.currentCallStatus!.type, member: nil, message: error?.localizedDescription)
            }
        }
    }
    
    func rejectByCallkit(calluuid: UUID?) {
        if let calluuid = calluuid {
            let endCallAction = CXEndCallAction(call: calluuid)
            self.cxController.requestTransaction(with: endCallAction) { err in
                guard err == nil else {
                    self.hangUpCall(callId: calluuid.toVGCallID())
                    return
                }
            }
        }
    }
    
    
    func rejectCall(callId: String?) {
        if let callId = callId {
            voiceClient.reject(callId) { error in
                self.currentCallStatus = CallStatus(uuid: UUID(uuidString: callId)!, state: .completed(remote: true, reason: nil), type: .inbound, member: nil, message: error?.localizedDescription)
            }
        }
    }
    
    func answerByCallkit(calluuid: UUID?) {
        if let calluuid = calluuid {
            
            let connectCallAction = CXAnswerCallAction(call: calluuid)
            print("transfer call")
            self.cxController.requestTransaction(with: connectCallAction) { err in
                guard err == nil else {
                    self.hangUpCall(callId: calluuid.toVGCallID())
                    return
                }
            }
        }
    }
    
    func answercall(callId:String?, completion:@escaping (_ isSucess: Bool) -> ()) {
 
        if let callId = callId {
            voiceClient.answer(callId) { error in
                if (error != nil) {
                    self.currentCallStatus = CallStatus(uuid: nil, state: .completed(remote: true, reason: .failed), type: .inbound, member: nil, message: error?.localizedDescription)
                    completion(false)
                }
                else {
                    if let memberName = self.memberName {
                        NotificationCenter.default.post(name: .callData, object: CallData(username: self.user.username, memberName: memberName, myLegId: callId, memberLegId: nil, region: self.user.region))
                    }
                    self.currentCallStatus = CallStatus(uuid: UUID(uuidString: callId)!, state: .answered, type: .inbound, member: nil, message: nil)

                    completion(true)
                }
            }
        }
        
    }
    
    
    func updateCallKit(call: CallStatus) {
        if (call.uuid == nil) {return}
        
        print("trigger update callkit state ", call.state)
        print("trigger update callkit type ", call.type)
        
        if (call.type == .outbound) {
            switch(call.state) {
                case .ringing:
                    // Outbound calls need reporting to callkit
                    if let to = call.member {
                        self.cxController.requestTransaction(
                            with: CXStartCallAction(call: call.uuid!, handle: CXHandle(type: .generic, value: to)),
                            completion: { err in
                                guard err == nil else {
                                    self.hangUpCall(callId: call.uuid?.toVGCallID())
                                    return
                                }
                                
                                self.callProvider.reportOutgoingCall(with: call.uuid!, startedConnectingAt: Date.now)
                                print("report outgoing call started")
                            }
                        )
                    }
                case .answered:
                    // Answers are remote by definition, so report them
                    print("report outgoing call connected")
                    self.callProvider.reportOutgoingCall(with: call.uuid!, connectedAt: Date.now)
                    
                case .completed:
                    // Report Remote Hangups + Cancels
                    print("call provider end outbound")
                    self.callProvider.reportCall(with: call.uuid!, endedAt: Date.now, reason: .remoteEnded)
            }
            
        }
        
        else if (call.type == .inbound) {
            switch (call.state) {
            case .ringing:
                // Report new Inbound calls so we follow PushKit and Callkit Rules
                let update = CXCallUpdate()
                update.localizedCallerName = call.member ?? "Vonage Call"
                update.supportsDTMF = false
                update.supportsHolding = false
                update.supportsGrouping = false
                update.hasVideo = false
                print("report new call here")
                self.callProvider.reportNewIncomingCall(with: call.uuid!, update: update) { err in
                    if err != nil {
                        self.rejectCall(callId: call.uuid?.toVGCallID())
                    }
                }
            case .completed:
                // Report Remote Hangups + Cancels
                print("call provider end inbound")
                self.callProvider.reportCall(with: call.uuid!, endedAt: Date.now, reason: .remoteEnded)
                
            default:
                // Nothing needed to report since answering requires local CXAction
                // Same for local hangups
                return
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
        self.memberName = caller
        print("here1 receive call")

        self.currentCallStatus = CallStatus(uuid: UUID(uuidString: callId)!, state: .ringing, type:.inbound, member: caller, message: nil)
    }
    
    func voiceClient(_ client: VGVoiceClient, didReceiveHangupForCall callId: String, withQuality callQuality: VGRTCQuality, isRemote: Bool) {
        print("here1 hangup call")
        if (isRemote) {
            self.currentCallStatus = CallStatus(uuid: UUID(uuidString: callId)!, state: .completed(remote: true, reason: nil), type: .outbound, member: nil, message: "User ends the call")
        }
    }
    
    func voiceClient(_ client: VGVoiceClient, didReceiveInviteCancelForCall callId: String, with reason: VGVoiceInviteCancelReasonType) {
        var callEndReason = "Incoming call failed"
        var cxreason: CXCallEndedReason = .failed
        
        switch (reason){
        case .remoteTimeout: callEndReason = "Incoming call unanswered"; cxreason = .unanswered
        case .remoteReject: callEndReason = "Incoming call declined elsewhere"; cxreason = .declinedElsewhere
        case .remoteAnswer: callEndReason = "Incoming call answered elsewhere"; cxreason = .answeredElsewhere
        case .remoteCancel: callEndReason = "Incoming call remote cancelled"; cxreason = .remoteEnded
        @unknown default:
            callEndReason = "Incoming call unknown error"
            fatalError()
        }
        
        let type = self.currentCallStatus == nil ? .inbound : self.currentCallStatus!.type
        self.currentCallStatus = CallStatus(uuid: UUID(uuidString: callId)!, state: .completed(remote: true, reason: cxreason), type:  type, member: nil, message: callEndReason)
    }
    
    func voiceClient(_ client: VGVoiceClient, didReceiveLegStatusUpdateForCall callId: String, withLegId legId: String, andStatus status: String) {
        // For our one to one calls, we are only really interested in answered legs
        if (status == "answered") {
            if let memberName = memberName {
                NotificationCenter.default.post(name: .callData, object: CallData(username: user.username, memberName: memberName, myLegId: callId, memberLegId: legId, region: user.region))
            }
             
            self.currentCallStatus = CallStatus(uuid: UUID(uuidString: callId)!, state: .answered, type: .outbound, member: nil, message: nil)
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
