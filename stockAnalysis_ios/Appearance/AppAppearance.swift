//
//  AppAppearance.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/24.
//

import UIKit

/// App 的外觀模式：跟隨系統 / 強制淺色 / 強制深色。
///
/// `rawValue` 用於持久化（存進 UserDefaults）；新增模式只要加 case，
/// 設定頁清單（取自 `allCases`）與套用邏輯都會自動跟著支援。
enum AppAppearance: String, CaseIterable {
    case system
    case light
    case dark

    /// 設定頁顯示用的名稱（依目前語系本地化）。
    var displayName: String {
        switch self {
        case .system: return L10n.Setting.appearanceSystem
        case .light: return L10n.Setting.appearanceLight
        case .dark: return L10n.Setting.appearanceDark
        }
    }

    /// 對應 UIKit 的介面風格；`.system` 用 `.unspecified` 表示交還給系統決定。
    var userInterfaceStyle: UIUserInterfaceStyle {
        switch self {
        case .system: return .unspecified
        case .light: return .light
        case .dark: return .dark
        }
    }
}
