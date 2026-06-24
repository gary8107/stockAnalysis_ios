//
//  AppTextSize.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/24.
//

import UIKit

/// App 內容字體大小選項。`scale` 為相對標準字級的倍率，套在內容渲染（markdown / 表格）上。
///
/// `rawValue` 用於持久化；新增級距只要加 case，設定頁清單與套用都會自動跟著支援。
enum AppTextSize: String, CaseIterable {
    case small
    case standard
    case large
    case extraLarge

    /// 設定頁顯示用的名稱（依目前語系本地化）。
    var displayName: String {
        switch self {
        case .small: return L10n.Setting.textSizeSmall
        case .standard: return L10n.Setting.textSizeStandard
        case .large: return L10n.Setting.textSizeLarge
        case .extraLarge: return L10n.Setting.textSizeExtraLarge
        }
    }

    /// 相對標準字級的倍率。內容渲染器以此縮放字體大小。
    var scale: CGFloat {
        switch self {
        case .small: return 0.85
        case .standard: return 1.0
        case .large: return 1.15
        case .extraLarge: return 1.3
        }
    }
}
