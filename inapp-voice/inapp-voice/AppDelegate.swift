//
//  AppDelegate.swift
//  inapp-voice
//
//  Created by iujie on 19/04/2023.
//

import UIKit
import AVFoundation
import PushKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

//    private let providerDelegate = ProviderDelegate()
    
    private let voipRegistry = PKPushRegistry(queue: nil)
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UIApplication.shared.delegate = self
        self.initialisePushTokens()
        
        
        // Application onboarding
        AVAudioSession.sharedInstance().requestRecordPermission { (granted:Bool) in
            print("Allow microphone use. Response: \(granted)")
        }
        
        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }
    // MARK: Notifications
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        
        PushToken.user = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // TODO: show alert
        print("error noti here")
    }
}

extension AppDelegate: PKPushRegistryDelegate {
    func initialisePushTokens() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    //
                    UIApplication.shared.registerForRemoteNotifications()
                    //
                    print("is granted!")
                    self.voipRegistry.delegate = self
                    self.voipRegistry.desiredPushTypes = [PKPushType.voIP]
                }
            }
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        if (type == PKPushType.voIP) {
            PushToken.voip = pushCredentials.token
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        switch (type){
        case .voIP:
            NotificationCenter.default.post(name: .handledPush, object: payload)
        default:
            return
        }
        completion()
    }
}

extension Notification.Name {
    static let clientStatus = Notification.Name("ClientStatus")
    static let callStatus = Notification.Name("CallStatus")
    static let callData = Notification.Name("CallData")
    static let handledCallCallKit = Notification.Name("CallHandledCallKit")
    static let handledCallApp = Notification.Name("CallHandledApp")
    static let handledPush = Notification.Name("CallPush")
}


