//
//  AppLanguage.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/8.
//

import Foundation

/// App 支援的語系清單。
///
/// `rawValue` 直接對應 App Bundle 內 `.lproj` 資料夾的名稱（例如 `en.lproj`、`zh-Hant.lproj`），
/// 切換語系時 `LocalizationManager` 會用它去載入對應的語系 Bundle。
/// 之後要新增語言（例如日文），只要在這裡加一個 case、再建立對應的 `.lproj` 即可，
/// 其餘流程（設定頁清單、Bundle 載入）都會自動跟著支援。
enum AppLanguage: String, CaseIterable {
    case english = "en"
    case traditionalChinese = "zh-Hant"
    case simplifiedChinese = "zh-Hans"

    /// 在設定頁語系清單顯示用的名稱。
    ///
    /// 刻意使用「該語言自身的寫法」（endonym），
    /// 這樣不論目前介面是什麼語系，使用者都能認得自己的母語選項。
    var displayName: String {
        switch self {
        case .english: return "English"
        case .traditionalChinese: return "繁體中文"
        case .simplifiedChinese: return "简体中文"
        }
    }

    /// 對應的 `Locale`，供日期、數字、貨幣等格式化時使用，
    /// 讓格式化結果與目前選擇的語系一致（而非跟著系統）。
    var locale: Locale {
        Locale(identifier: rawValue)
    }

    /// 從系統偏好語言挑出第一個 App 有支援的語系；都不支援時回退到英文。
    ///
    /// 用於使用者「第一次開啟 App、尚未手動選過語系」時決定預設值，
    /// 讓初次體驗盡量貼近使用者的系統語言。
    static func systemPreferred() -> AppLanguage {
        for preferred in Locale.preferredLanguages {
            // 系統回傳的代碼可能帶地區（例如 "zh-Hant-TW"、"en-US"），用前綴比對即可命中。
            if let matched = allCases.first(where: { preferred.hasPrefix($0.rawValue) }) {
                return matched
            }

            // 額外處理中文的舊式/地區代碼：
            // 系統可能給 "zh-TW"、"zh-HK"（繁體）或 "zh-CN"、"zh-SG"（簡體），
            // 這些不會直接命中上面的 zh-Hant / zh-Hans，所以在這裡做語系判斷。
            if preferred.hasPrefix("zh") {
                let isSimplified = preferred.contains("Hans")
                    || preferred.contains("CN")
                    || preferred.contains("SG")
                return isSimplified ? .simplifiedChinese : .traditionalChinese
            }
        }
        return .english
    }
}
