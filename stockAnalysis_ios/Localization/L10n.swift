//
//  L10n.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/8.
//

import Foundation

/// 集中收斂所有本地化字串的「型別安全入口」。
///
/// 為什麼要有這層而不是到處寫魔術字串（如 `"tab.setting".localized`）：
/// - **避免拼錯 key**：呼叫端用 `L10n.Tab.setting`，編譯期就能檢查，不會打錯字。
/// - **集中管理**：所有用到的 key 一目了然，方便對照 `.strings` 是否齊全。
/// - **支援即時切換**：刻意使用 `computed` 屬性（每次存取才查表），
///   而非 `static let`（只會在第一次計算後固定），這樣語系切換後重新讀取就會拿到新語言。
enum L10n {

    /// 跨頁面共用的通用字串。
    enum Common {
        static var cancel: String { "common.cancel".localized }
    }

    /// 底部 TabBar 的標題。
    enum Tab {
        static var comparison: String { "tab.comparison".localized }
        static var analyst: String { "tab.analyst".localized }
        static var setting: String { "tab.setting".localized }
    }

    /// 設定頁的文字。
    enum Setting {
        static var title: String { "setting.title".localized }
        static var sectionLanguage: String { "setting.section.language".localized }
        static var sectionLanguageFooter: String { "setting.section.language.footer".localized }
    }

    /// 比較頁的文字。
    enum Comparison {
        static var title: String { "comparison.title".localized }
        static var empty: String { "comparison.empty".localized }
        /// 帶數量的摘要，例如「3 筆比較資料」。
        /// - Parameter count: 比較資料筆數，對應 `.strings` 內的 `%d`。
        static func summary(count: Int) -> String { "comparison.summary".localized(with: count) }
    }

    /// 分析師頁的文字。
    enum Analyst {
        static var title: String { "analyst.title".localized }
        static var empty: String { "analyst.empty".localized }
        /// 帶數量的摘要，例如「4 位分析師」。
        /// - Parameter count: 分析師人數，對應 `.strings` 內的 `%d`。
        static func summary(count: Int) -> String { "analyst.summary".localized(with: count) }
    }
}
