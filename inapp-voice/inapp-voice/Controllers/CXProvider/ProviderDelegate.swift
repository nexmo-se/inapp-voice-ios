//
//  ProviderDelegate.swift
//  inapp-voice
//
//  Created by iujie on 24/04/2023.
//

import Foundation
import CallKit
import AVFAudio

struct PushCall {
    var caller: String?
    var uuid: UUID?
    var answerAction: CXAnswerCallAction?
}

final class ProviderDelegate: NSObject {
    private let provider: CXProvider
    private let callController = CXCallController()
    private var activeCall: PushCall? = PushCall()
    
    override init() {
        provider = CXProvider(configuration: ProviderDelegate.providerConfiguration)
        super.init()
        provider.setDelegate(self, queue: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(callReceived(_:)), name: .incomingCall, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(callHandled), name: .handledCallApp, object:nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    static var providerConfiguration: CXProviderConfiguration = {
        let providerConfiguration = CXProviderConfiguration()
        providerConfiguration.supportsVideo = false
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.supportedHandleTypes = [.generic]
        return providerConfiguration
    }()
}


extension ProviderDelegate: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        activeCall = PushCall()
    }
    
    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        NotificationCenter.default.post(name: .handledCallCallKit, object: nil)
        configureAudioSession()
        
        activeCall?.answerAction = action
        
        if activeCall?.caller != nil {
            action.fulfill()
        }
    }
    
    private func answerCall(with action: CXAnswerCallAction) {
        print("answer call action")
//        activeCall?.call?.answer(nil)
//        activeCall?.call?.setDelegate(self)
//        activeCall?.uuid = action.callUUID
//        action.fulfill()
    }
    
    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        print("call ended action")
//        hangup()
//        action.fulfill()
    }

    func provider(_ provider: CXProvider, didActivate audioSession: AVAudioSession) {
        print("audiosession did activate")
//        assert(activeCall?.answerAction != nil, "Call not ready - see provider(_:perform:CXAnswerCallAction)")
//        assert(activeCall?.caller != nil, "Call not ready - see callReceived")
//        answerCall(with: activeCall!.answerAction!)
    }

    func provider(_ provider: CXProvider, didDeactivate audioSession: AVAudioSession) {
        print("did hangup call")
//        hangup()
    }

    func reportCall(callerID: String) {
        let update = CXCallUpdate()
        let callerUUID = UUID()
        
        update.remoteHandle = CXHandle(type: .generic, value: callerID)
        update.localizedCallerName = callerID
        update.hasVideo = false
        
        provider.reportNewIncomingCall(with: callerUUID, update: update) { [weak self] error in
            guard error == nil else { return }
            self?.activeCall?.uuid = callerUUID
        }
    }

    /*
     If the app is in the foreground and the call is answered via the
     ViewController alert, there is no need to display the CallKit UI.
     */
    @objc private func callHandled() {
        // TODO: always use callkit?
//        provider.invalidate()
    }

    @objc private func callReceived(_ notification: NSNotification) {
        
        print("call received in callkit")
//        if let call = notification.object as? NXMCall {
//            activeCall?.call = call
//            activeCall?.answerAction?.fulfill()
//        }
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
