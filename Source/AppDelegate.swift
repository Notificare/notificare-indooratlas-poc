//
//  AppDelegate.swift
//  Inbox
//
//  Created by Helder Pinhal on 12/05/2020.
//  Copyright © 2020 Notificare. All rights reserved.
//

import UIKit
import IndoorAtlas

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate, NotificarePushLibDelegate, IALocationManagerDelegate {

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        
        setupNotificare()
        setupIndoorAtlas()
        
        return true
    }
    
    private func setupNotificare() {
        if #available(iOS 14.0, *) {
            NotificarePushLib.shared().presentationOptions = [.banner, .sound, .badge]
        } else {
            NotificarePushLib.shared().presentationOptions = [.alert, .sound, .badge]
        }
        
        NotificarePushLib.shared().initialize(withKey: nil, andSecret: nil)
        NotificarePushLib.shared().delegate = self
        NotificarePushLib.shared().launch()
    }
    
    private func setupIndoorAtlas() {
        guard let path = Bundle.main.path(forResource: "IndoorAtlas", ofType: "plist"), let plist = NSDictionary(contentsOfFile: path) else {
            fatalError("Missing IndoorAtlas.plist.")
        }
        
        guard let key = plist["API_KEY"] as? String, let secret = plist["API_SECRET"] as? String else {
            fatalError("Invalid contents of IndoorAtlas.plist")
        }
        
        IALocationManager.sharedInstance().setApiKey(key, andSecret: secret)
        IALocationManager.sharedInstance().delegate = self
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

    // MARK: Notificare
    
    func notificarePushLib(_ library: NotificarePushLib, onReady application: NotificareApplication) {
        // At this point you have been assigned a temporary device identifier
        // All services subscribed can be used
        
        NotificarePushLib.shared().registerForNotifications()
        
        IALocationManager.sharedInstance().desiredAccuracy = .iaLocationAccuracyBest
        IALocationManager.sharedInstance().startUpdatingLocation()
    }
    
    func notificarePushLib(_ library: NotificarePushLib, didLoadInbox items: [NotificareDeviceInbox]) {
        NotificationCenter.default.post(name: Notification.Name.UpdateInbox, object: nil)
    }
    
    func notificarePushLib(_ library: NotificarePushLib, didReceiveRemoteNotificationInForeground notification: NotificareNotification, withController controller: Any?) {
        NotificationCenter.default.post(name: Notification.Name.UpdateInbox, object: nil)
    }
    
    // MARK: IA Location Manager
    
    @objc func indoorLocationManager(_ manager: IALocationManager, didEnter region: IARegion) {
        print("---> Did enter region: \(region.name ?? "---")")
        
        NotificarePushLib.shared().logCustomEvent("region.enter", withData: eventData(for: region)) { _, error in
            if let error = error {
                print("Failed to log custom event: \(error)")
                return
            }
            
            print("Logged custom event to Notificare.")
        }
    }
    
    @objc func indoorLocationManager(_ manager: IALocationManager, didExitRegion region: IARegion) {
        print("---> Did exit region : \(region.name ?? "---")")
        
        NotificarePushLib.shared().logCustomEvent("region.exit", withData: eventData(for: region)) { _, error in
            if let error = error {
                print("Failed to log custom event: \(error)")
                return
            }
            
            print("Logged custom event to Notificare.")
        }
    }
    
    private func eventData(for region: IARegion) -> [String: String] {
        var data: [String: String] = [
            "identifier": region.identifier,
        ]
        
        if let name = region.name {
            data["name"] = name
        }
        
        if let timestamp = region.timestamp {
            data["timestamp"] = "\(Int(timestamp.timeIntervalSince1970 * 1000))"
        }
        
        if let venue = region.venue {
            data["venueId"] = venue.id
            data["venueName"] = venue.name
        }
        
        if let floorplan = region.floorplan {
            if let id = floorplan.floorPlanId {
                data["floorplanId"] = id
            }
            
            if let name = floorplan.name {
                data["floorplanName"] = name
            }
            
            if let level = floorplan.floor?.level {
                data["floorplanLevel"] = "\(level)"
            }
        }
        
        return data
    }
}
