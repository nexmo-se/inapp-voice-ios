//
//  PushController.swift
//  inapp-voice
//
//  Created by iujie on 21/04/2023.
//


import Foundation
import PushKit
import UIKit
import UserNotifications

typealias PushToken = (user:Data,voip:Data)

class PushController: NSObject {
    
    private let voipRegistry = PKPushRegistry(queue: nil)

    // Delegate Subjects
    var pushKitToken: Data?
    var notificationToken: Data?
    var voipPush:PKPushPayload?

    override init() {
        super.init()
    }
}

extension PushController {
    
    func initialisePushTokens() {
        
//        NotificationCenter.default
//            .publisher(for: NSNotification.didRegisterForRemoteNotificationNotification)
//            .compactMap { n  in n.userInfo!["data"] as? Data?}
//            .first()
//            .sink {
//                if $0 != nil {
//                    self.notificationToken = $0
//                }
//            }.cancel()
//
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
//            if granted {
//                DispatchQueue.main.async {
//                    //
//                    UIApplication.shared.registerForRemoteNotifications()
//                    //
//                    self.voipRegistry.delegate = self
//                    self.voipRegistry.desiredPushTypes = [PKPushType.voIP]
//                }
//            }
//        }
    }
}


extension PushController: PKPushRegistryDelegate {
        
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if (type == PKPushType.voIP) {
            self.pushKitToken = pushCredentials.token
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
            
        switch (type){
        case .voIP:
            self.voipPush = payload
        default:
            return
        }
        completion()
    }
    
}

