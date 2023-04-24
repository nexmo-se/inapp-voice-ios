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

    // Delegate Subjects
    var voipPush:PKPushPayload?
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        UIApplication.shared.delegate = self
        self.initialisePushTokens()
        
        
        // Application onboarding
        let mediaType = AVMediaType.audio
        let authorizationStatus = AVCaptureDevice.authorizationStatus(for: mediaType)
        switch authorizationStatus {
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: mediaType) { granted in
                print("🎤 access \(granted ? "granted" : "denied")")
            }
        case .authorized, .denied, .restricted:
            print("auth")
        @unknown default:
            print("error avcapture")
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
        
        print("set user token")
        PushToken.user = deviceToken
    }

    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        // TODO: show alert
        print("error noti here")
        NotificationCenter.default.post(name: NSNotification.didFailToRegisterForRemoteNotification, object: error.localizedDescription)
    }
}

extension AppDelegate: PKPushRegistryDelegate {
    func initialisePushTokens() {
        print("receive abc")
       
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    //
                    UIApplication.shared.registerForRemoteNotifications()
                    //
                    print("is granted!")
                    self.voipRegistry.delegate = self
                    self.voipRegistry.desiredPushTypes = [PKPushType.voIP]
                    
                    print("old token", self.voipRegistry.pushToken(for: .voIP))
                }
            }
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didUpdate pushCredentials: PKPushCredentials, for type: PKPushType) {
        print("receive voip token1 ", type)
        if (type == PKPushType.voIP) {
            PushToken.voip = pushCredentials.token
            print("receive voip token")
        }
    }
    
    func pushRegistry(_ registry: PKPushRegistry, didReceiveIncomingPushWith payload: PKPushPayload, for type: PKPushType, completion: @escaping () -> Void) {
        print("receive iujie1", payload)
        switch (type){
        case .voIP:
            self.voipPush = payload
        default:
            return
        }
        completion()
    }
    
    func pushRegistry(_: PKPushRegistry, didInvalidatePushTokenFor: PKPushType) {
        print("iujie 1")
    }
    
}

extension NSNotification {
    public static let didRegisterForRemoteNotificationNotification = NSNotification.Name("didRegisterForRemoteNotificationWithDeviceTokenNotification")
    public static let didFailToRegisterForRemoteNotification = NSNotification.Name("didFailToRegisterForRemoteNotificationsWithErrorNotification")

}


