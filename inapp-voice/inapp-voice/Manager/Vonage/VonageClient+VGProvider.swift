//
//  VonageClient+VGProvider.swift
//  inapp-voice
//
//  Created by iujie on 27/04/2023.
//

import Foundation
import VonageClientSDKVoice
import CallKit

extension VonageClient: VGVoiceClientDelegate {
    func voiceClient(_ client: VGVoiceClient, didReceiveInviteForCall callId: VGCallId, from caller: String, with type: VGVoiceChannelType) {
        self.memberName = caller
        self.currentCallStatus = CallStatusModel(uuid: UUID(uuidString: callId)!, state: .ringing, type:.inbound, member: caller, message: nil)
    }
    
    func voiceClient(_ client: VGVoiceClient, didReceiveHangupForCall callId: VGCallId, withQuality callQuality: VGRTCQuality, reason: VGHangupReason) {
        let type = self.currentCallStatus == nil ? .outbound : self.currentCallStatus!.type
        self.currentCallStatus = CallStatusModel(uuid: UUID(uuidString: callId)!, state: .completed(remote: true, reason: nil), type: type, member: nil, message: "Call ended by caller/callee")
    }
    
    func voiceClient(_ client: VGVoiceClient, didReceiveInviteCancelForCall callId: String, with reason: VGVoiceInviteCancelReason) {
        var callEndReason = "Incoming call failed"
        var cxreason: CXCallEndedReason = .failed
        
        switch (reason){
        case .remoteTimeout: callEndReason = "Incoming call unanswered"; cxreason = .unanswered
        case .rejectedElsewhere: callEndReason = "Incoming call declined elsewhere"; cxreason = .declinedElsewhere
        case .answeredElsewhere: callEndReason = "Incoming call answered elsewhere"; cxreason = .answeredElsewhere
        case .remoteCancel: callEndReason = "Incoming call remote cancelled"; cxreason = .remoteEnded
        case .unknown:
            callEndReason = "Incoming call unknown error"; cxreason = .remoteEnded
        @unknown default:
           
            fatalError()
        }
        
        let type = self.currentCallStatus == nil ? .inbound : self.currentCallStatus!.type
        self.currentCallStatus = CallStatusModel(uuid: UUID(uuidString: callId)!, state: .completed(remote: true, reason: cxreason), type:  type, member: nil, message: callEndReason)
    }
    
    func voiceClient(_ client: VGVoiceClient, didReceiveLegStatusUpdateForCall callId: VGCallId, withLegId legId: String, andStatus status: VGLegStatus) {
        if (status == .answered) {
            if let memberName = memberName {
                NotificationCenter.default.post(name: .handledCallData, object: CallDataModel(username: user.username, memberName: memberName, myLegId: callId, memberLegId: legId, region: user.region))
            }
            
            self.currentCallStatus = CallStatusModel(uuid: UUID(uuidString: callId)!, state: .answered, type: .outbound, member: nil, message: nil)
        }
    }
    
    func client(_ client: VGBaseClient, didReceiveSessionErrorWith reason: VGSessionErrorReason) {
        let statusText: String
        
        switch reason {
        case .tokenExpired:
            statusText = "Session Token Expired"
        case .pingTimeout, .transportClosed:
            statusText = "Session Network Error"
        case .unknown:
            statusText = "Session Unknown Error"
        @unknown default:
            statusText = "Session Unknown Error"
        }
        
        NotificationCenter.default.post(name: .clientStatus, object: VonageClientStatusModel(state: .disconnected, message: statusText))
    }
}