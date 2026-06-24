//
//  AppearanceManager.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/24.
//

import UIKit

/// 集中管理「App 外觀模式」的核心元件（深 / 淺 / 跟隨系統）。
///
/// 設計取捨（為什麼這樣做）：
/// - **以 `window.overrideUserInterfaceStyle` 套用**：這是 iOS 13 起官方做法，
///   設定後整個畫面（用 semantic colors 的部分）會即時切換，且系統會自帶平滑轉場，**不需重建畫面**。
/// - **狀態持久化、啟動即套用**：選擇存進 `UserDefaults`，App 啟動時於 SceneDelegate 套到 window，
///   讓使用者的選擇跨次啟動保留。
/// - **可注入 `UserDefaults`**：方便測試時替換成乾淨儲存體（與 LocalizationManager 一致）。
final class AppearanceManager {

    /// 全 App 共用的外觀管理單例。
    static let shared = AppearanceManager()

    private let storageKey = "app.appearance"
    private let userDefaults: UserDefaults

    /// 目前外觀模式。
    private(set) var current: AppAppearance

    /// - Parameter userDefaults: 持久化用的儲存體，預設 `.standard`，可注入以利測試。
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let raw = userDefaults.string(forKey: storageKey),
           let appearance = AppAppearance(rawValue: raw) {
            current = appearance
        } else {
            current = .system
        }
    }

    /// 切換外觀模式：持久化並即時套用到目前作用中的 window。相同模式不做事。
    func setAppearance(_ appearance: AppAppearance) {
        guard appearance != current else { return }
        current = appearance
        userDefaults.set(appearance.rawValue, forKey: storageKey)
        apply(to: UIApplication.shared.activeKeyWindow)
    }

    /// 把目前外觀套到指定 window（啟動時與重建 root 後呼叫）。
    func apply(to window: UIWindow?) {
        window?.overrideUserInterfaceStyle = current.userInterfaceStyle
    }
}
