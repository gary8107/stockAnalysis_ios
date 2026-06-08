//
//  LocalizationManager.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/8.
//

import Foundation

extension Notification.Name {
    /// 語系切換完成後發出。
    /// 需要即時刷新文字的畫面可以訂閱這個通知，重新套用本地化字串。
    static let appLanguageDidChange = Notification.Name("app.languageDidChange")
}

/// 集中管理「App 當前語系」的核心元件。
///
/// 設計取捨（為什麼這樣做）：
/// - **App 內語系獨立於系統語系**：使用者能在設定頁自由切換，且即時生效、不需重開 App。
/// - **不採用改寫 `AppleLanguages` 的做法**：那種方式要重新啟動才會完整生效，體驗不佳；
///   這裡改成自己持有「對應語系的 `.lproj` Bundle」，所有本地化查表都走這個 bundle，
///   因此切換語系後只要刷新畫面即可立刻看到新語言。
/// - **核心邏輯保持單純、可注入**：`UserDefaults` 由外部注入，方便寫單元測試時替換成乾淨的儲存體。
///
/// 對外以 `shared` 單例使用（語系是全 App 共用的狀態），
/// 但建構式開放注入，並未把邏輯綁死在單例上，保留測試彈性。
final class LocalizationManager {

    /// 全 App 共用的語系管理單例。
    static let shared = LocalizationManager()

    /// 持久化使用者語系選擇用的 `UserDefaults` key。
    private let storageKey = "app.selectedLanguage"

    /// 注入的儲存體，預設為 `.standard`，測試時可替換。
    private let userDefaults: UserDefaults

    /// 目前語系。
    ///
    /// 設定新值時會：持久化 → 重新載入語系 Bundle → 發出 `appLanguageDidChange` 通知。
    /// 相同語系不會觸發任何副作用（透過 `oldValue` 判斷），避免無意義的刷新。
    private(set) var currentLanguage: AppLanguage {
        didSet {
            guard oldValue != currentLanguage else { return }
            userDefaults.set(currentLanguage.rawValue, forKey: storageKey)
            reloadBundle()
            NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
        }
    }

    /// 對應 `currentLanguage` 的語系 Bundle，是本地化字串查表的實際來源。
    /// 找不到對應 `.lproj` 時會退回 `Bundle.main`，確保至少能顯示 key 或 Base 內容。
    private(set) var bundle: Bundle = .main

    /// - Parameter userDefaults: 儲存語系選擇用的儲存體，預設 `.standard`，可注入以利測試。
    init(userDefaults: UserDefaults = .standard) {
        self.userDefaults = userDefaults

        // 啟動時決定語系：優先沿用使用者上次的選擇；
        // 從未選過（或存了不認得的值）時，才依系統偏好語言挑一個支援的語系當預設。
        if let saved = userDefaults.string(forKey: storageKey),
           let language = AppLanguage(rawValue: saved) {
            currentLanguage = language
        } else {
            currentLanguage = AppLanguage.systemPreferred()
        }

        reloadBundle()
    }

    /// 切換語系。相同語系不會有任何動作。
    /// - Parameter language: 要切換到的目標語系。
    func setLanguage(_ language: AppLanguage) {
        currentLanguage = language
    }

    /// 用 key 取得「目前語系」的本地化字串。
    /// - Parameters:
    ///   - key: `Localizable.strings` 內的鍵。
    ///   - table: `.strings` 檔名（不含副檔名），預設 `nil` 即使用 `Localizable.strings`。
    /// - Returns: 對應語系的字串；查不到時 `localizedString` 會原樣回傳 key。
    func localizedString(forKey key: String, table: String? = nil) -> String {
        bundle.localizedString(forKey: key, value: nil, table: table)
    }

    /// 依 `currentLanguage` 載入對應的 `.lproj` Bundle。
    /// 找不到對應資源時退回 `Bundle.main`，避免整個查表失效。
    private func reloadBundle() {
        guard let path = Bundle.main.path(forResource: currentLanguage.rawValue, ofType: "lproj"),
              let languageBundle = Bundle(path: path) else {
            bundle = .main
            return
        }
        bundle = languageBundle
    }
}
