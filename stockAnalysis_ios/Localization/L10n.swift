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
        static var loading: String { "common.loading".localized }
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

        // 外觀模式
        static var sectionAppearance: String { "setting.section.appearance".localized }
        static var appearanceSystem: String { "setting.appearance.system".localized }
        static var appearanceLight: String { "setting.appearance.light".localized }
        static var appearanceDark: String { "setting.appearance.dark".localized }

        // 字體大小
        static var sectionTextSize: String { "setting.section.textSize".localized }
        static var sectionTextSizeFooter: String { "setting.section.textSize.footer".localized }
        static var textSizeSmall: String { "setting.textSize.small".localized }
        static var textSizeStandard: String { "setting.textSize.standard".localized }
        static var textSizeLarge: String { "setting.textSize.large".localized }
        static var textSizeExtraLarge: String { "setting.textSize.extraLarge".localized }

        // 語言
        static var sectionLanguage: String { "setting.section.language".localized }
        static var sectionLanguageFooter: String { "setting.section.language.footer".localized }

        // 資料訊息
        static var sectionData: String { "setting.section.data".localized }
        static var dataLastUpdate: String { "setting.data.lastUpdate".localized }
        static var dataAnalysts: String { "setting.data.analysts".localized }
        static var dataNotes: String { "setting.data.notes".localized }
        static var dataComparisons: String { "setting.data.comparisons".localized }
        /// 無對應資料時顯示的占位字串。
        static var dataNoValue: String { "setting.data.noValue".localized }

        // 關於
        static var sectionAbout: String { "setting.section.about".localized }
        static var aboutVersion: String { "setting.about.version".localized }
        static var aboutSource: String { "setting.about.source".localized }
        /// 關於區塊的 footer：App 介紹文字。
        static var aboutIntro: String { "setting.about.intro".localized }
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
        /// 選定分析師於選定日期沒有可顯示內容時的提示。
        static var contentEmpty: String { "analyst.content.empty".localized }
        /// 帶數量的摘要，例如「4 位分析師」。
        /// - Parameter count: 分析師人數，對應 `.strings` 內的 `%d`。
        static func summary(count: Int) -> String { "analyst.summary".localized(with: count) }
    }
}
