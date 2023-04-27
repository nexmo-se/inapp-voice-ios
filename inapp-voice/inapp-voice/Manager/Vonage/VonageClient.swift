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

struct PushInfo {
    let user: Data
    let voip: Data
}

class VonageClient: NSObject {
    let voiceClient:VGVoiceClient
    var user: UserModel
    var memberName: String?
    var currentCallStatus: CallStatusModel? {
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
        VGBaseClient.setDefaultLoggingLevel(.error)
        self.voiceClient  = vonageClient
        super.init()
        self.voiceClient.delegate = self
    }
    
    func login(user: UserModel) {
        self.voiceClient.createSession(user.token) { error, session in
            if error == nil {
                NotificationCenter.default.post(name: .clientStatus, object: VonageClientStatusModel(state: .connected, message: nil))
                self.registerPushTokens()
                
            } else {
                NotificationCenter.default.post(name: .clientStatus, object: VonageClientStatusModel(state: .disconnected, message: error!.localizedDescription))
            }
        }
    }
    
    func logout() {
        self.voiceClient.deleteSession { error in
            if error != nil {
                NotificationCenter.default.post(name: .clientStatus, object: VonageClientStatusModel(state: .disconnected, message: error!.localizedDescription))
            }
            else {
                NotificationCenter.default.post(name: .clientStatus, object: VonageClientStatusModel(state: .disconnected, message: nil))
            }
        }
        UserDefaults.standard.removeObject(forKey: Constants.pushToken)
        NotificationCenter.default.removeObserver(self)
    }
    
    
    func startOutboundCall(member: String) {
        voiceClient.serverCall(["to": member]) { error, callId in
            if error != nil {
                self.currentCallStatus = CallStatusModel(uuid: nil, state: .completed(remote: false, reason: .failed), type: .outbound, member: nil, message: error!.localizedDescription)
            } else {
                
                if let callId = callId {
                    self.memberName = member
                    self.currentCallStatus = CallStatusModel(uuid: UUID(uuidString: callId)!, state: .ringing, type: .outbound, member: member, message: nil)
                }
            }
        }
    }
    
    func registerPushTokens() {
        if (PushToken.voip == nil || PushToken.user == nil) { return }
        
        self.voiceClient.registerDevicePushToken(PushToken.voip!, userNotificationToken: PushToken.user!, isSandbox: true) { error, device in
            if (error != nil) {
                self.logout()
            }
            
            // Reset observer
            NotificationCenter.default.removeObserver(self)
            
            // Attached Observer
            NotificationCenter.default.addObserver(self, selector: #selector(self.reportVoipPush(_:)), name: .handledPush, object: nil)
        }
    }
    
    func hangUpCall(callId: String?) {
        if let callId = callId {
            voiceClient.hangup(callId) { error in
                self.currentCallStatus = CallStatusModel(uuid: UUID(uuidString: callId)!, state: .completed(remote: false, reason: nil), type: self.currentCallStatus!.type, member: nil, message: error?.localizedDescription)
            }
        }
    }
    
    func rejectByCallkit(calluuid: UUID?) {
        if let calluuid = calluuid {
            let endCallAction = CXEndCallAction(call: calluuid)
            self.cxController.requestTransaction(with: endCallAction) { error in
                guard error == nil else {
                    self.hangUpCall(callId: calluuid.toVGCallID())
                    return
                }
            }
        }
    }
    
    func rejectCall(callId: String?) {
        if let callId = callId {
            voiceClient.reject(callId) { error in
                self.currentCallStatus = CallStatusModel(uuid: UUID(uuidString: callId)!, state: .completed(remote: true, reason: nil), type: .inbound, member: nil, message: error?.localizedDescription)
            }
        }
    }
    
    func answerByCallkit(calluuid: UUID?) {
        if let calluuid = calluuid {
            
            let connectCallAction = CXAnswerCallAction(call: calluuid)
            self.cxController.requestTransaction(with: connectCallAction) { error in
                guard error == nil else {
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
                    self.currentCallStatus = CallStatusModel(uuid: nil, state: .completed(remote: true, reason: .failed), type: .inbound, member: nil, message: error?.localizedDescription)
                    completion(false)
                }
                else {
                    if let memberName = self.memberName {
                        NotificationCenter.default.post(name: .handledCallData, object: CallDataModel(username: self.user.username, memberName: memberName, myLegId: callId, memberLegId: nil, region: self.user.region))
                    }
                    self.currentCallStatus = CallStatusModel(uuid: UUID(uuidString: callId)!, state: .answered, type: .inbound, member: nil, message: nil)
                    
                    completion(true)
                }
            }
        }
        
    }
    
    func updateCallKit(call: CallStatusModel) {
        if (call.uuid == nil) {return}
        
        if (call.type == .outbound) {
            switch(call.state) {
            case .ringing:
                if let to = call.member {
                    self.cxController.requestTransaction(
                        with: CXStartCallAction(call: call.uuid!, handle: CXHandle(type: .generic, value: to)),
                        completion: { error in
                            guard error == nil else {
                                self.hangUpCall(callId: call.uuid?.toVGCallID())
                                return
                            }
                            
                            self.callProvider.reportOutgoingCall(with: call.uuid!, startedConnectingAt: Date.now)
                        }
                    )
                }
            case .answered:
                self.callProvider.reportOutgoingCall(with: call.uuid!, connectedAt: Date.now)
                
            case .completed:
                self.callProvider.reportCall(with: call.uuid!, endedAt: Date.now, reason: .remoteEnded)
            }
            
        }
        
        else if (call.type == .inbound) {
            switch (call.state) {
            case .ringing:
                let update = CXCallUpdate()
                update.localizedCallerName = call.member ?? "Vonage Call"
                update.supportsDTMF = false
                update.supportsHolding = false
                update.supportsGrouping = false
                update.hasVideo = false
                self.callProvider.reportNewIncomingCall(with: call.uuid!, update: update) { error in
                    if error != nil {
                        self.rejectByCallkit(calluuid: call.uuid)
                    }
                }
            case .completed:
                self.callProvider.reportCall(with: call.uuid!, endedAt: Date.now, reason: .remoteEnded)
                
            default:
                return
            }
        }
        
    }
    
    @objc private func reportVoipPush(_ notification: NSNotification) {
        if let payload = notification.object as? PKPushPayload {
            self.voiceClient.processCallInvitePushData(payload.dictionaryPayload)
            
        }
    }
}
