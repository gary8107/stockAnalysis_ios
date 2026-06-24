//
//  TextSizeManager.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/24.
//

import UIKit

/// 集中管理「App 內容字體大小」的核心元件。
///
/// 設計取捨（為什麼這樣做）：
/// - **只縮放內容文字**：App 多數 UI 用固定字級，這裡的倍率只套在「主要閱讀內容」
///   （`MarkdownRenderer` 與 `ContentTableView`），也就是筆記與表格——使用者真正在讀的部分。
/// - **靠重建首頁套用**：字級在內容建構當下讀取，切換後由設定頁重建首頁（與語系切換相同做法），
///   讓各頁以新倍率重新產生內容，不必在每個元件接通知。
/// - **可注入 `UserDefaults`**：方便測試。
final class TextSizeManager {

    /// 全 App 共用的字體大小管理單例。
    static let shared = TextSizeManager()

    private let storageKey = "app.textSize"
    private let userDefaults: UserDefaults

    /// 目前字體大小選項。
    private(set) var current: AppTextSize

    /// 內容渲染要用的倍率。
    var scale: CGFloat { current.scale }

    /// - Parameter userDefaults: 持久化用的儲存體，預設 `.standard`，可注入以利測試。
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults
        if let raw = userDefaults.string(forKey: storageKey),
           let size = AppTextSize(rawValue: raw) {
            current = size
        } else {
            current = .standard
        }
    }

    /// 切換字體大小：持久化。相同選項不做事。實際套用由呼叫端重建首頁完成。
    func setTextSize(_ size: AppTextSize) {
        guard size != current else { return }
        current = size
        userDefaults.set(size.rawValue, forKey: storageKey)
    }
}
