//
//  AppDelegate.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/1.
//

import UIKit

@main
class AppDelegate: UIResponder, UIApplicationDelegate {

    /// 本專案採用 Scene-based 架構，window 實際由 SceneDelegate 持有。
    /// 但 CYLTabBarController 內部的 getMainWindow() 會去讀 `appDelegate.window`，
    /// 若 AppDelegate 沒有這個屬性會丟出 unrecognized selector 而崩潰。
    /// 因此在此宣告 window（維持 nil），讓它能安全回傳 nil 並改走 connectedScenes 取得正確的 window。
    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
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


}

