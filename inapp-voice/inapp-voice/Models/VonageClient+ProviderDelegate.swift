//
//  VonageClient+ProviderDelegate.swift
//  inapp-voice
//
//  Created by iujie on 25/04/2023.
//

import Foundation
import VonageClientSDKVoice
import AudioToolbox
import CallKit


extension VonageClient: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
    }
    
    func provider(_ provider: CXProvider, perform action: CXStartCallAction) {
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction){
        
        if (self.currentCallStatus == nil || self.currentCallStatus!.uuid == nil) {
            action.fail()
            return
        }
        
        configureAudioSession()
        
        answercall(callId: self.currentCallStatus?.uuid?.toVGCallID()) { isSucess in
            if (!isSucess) {
                provider.reportCall(with: action.callUUID, endedAt: Date.now, reason: .failed)
            }
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction){
        if (self.currentCallStatus == nil || self.currentCallStatus!.uuid == nil) {
            action.fail()
            return
        }
            
        if self.currentCallStatus!.type == .inbound {
            rejectCall(callId: self.currentCallStatus?.uuid?.toVGCallID())
        }
        else {
            hangUpCall(callId: self.currentCallStatus?.uuid?.toVGCallID())
        }
                           
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        if (self.currentCallStatus == nil || self.currentCallStatus!.uuid == nil) {
            action.fail()
            return
        }
        
        if (action.isMuted == true) {
            self.voiceClient.mute(action.callUUID.toVGCallID()) { err in
                print("mute error")
            }
        }
        else {
            self.voiceClient.unmute(action.callUUID.toVGCallID()) { err in
                print("unmute error")
            }
        }
        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession){
        VGVoiceClient.enableAudio(audioSession)
    }
    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession){
        VGVoiceClient.disableAudio(audioSession)
    }
    
    // When the device is locked, the AVAudioSession needs to be configured.
       private func configureAudioSession() {
           let audioSession = AVAudioSession.sharedInstance()
           do {
               try audioSession.setCategory(AVAudioSession.Category.playAndRecord, mode: .default)
               try audioSession.setMode(AVAudioSession.Mode.voiceChat)
           } catch {
               print(error)
           }
       }
}
