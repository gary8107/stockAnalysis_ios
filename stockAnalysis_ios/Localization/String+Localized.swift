//
//  String+Localized.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/8.
//

import Foundation

extension String {
    /// 把自己當成 key，取得「目前語系」（`LocalizationManager`）的本地化字串。
    ///
    /// 用法：`"tab.setting".localized`
    ///
    /// 注意：這裡刻意不用系統的 `NSLocalizedString`，因為那會跟著系統語系走；
    /// 改成查 `LocalizationManager` 持有的語系 bundle，才能支援 App 內即時切換。
    var localized: String {
        LocalizationManager.shared.localizedString(forKey: self)
    }

    /// 帶參數的本地化字串，內部以 `String(format:)` 套用。
    ///
    /// 用法：`"greeting.hello".localized(with: userName)`
    /// 對應 `.strings`：`"greeting.hello" = "Hello, %@";`
    /// - Parameter arguments: 依 `.strings` 內格式符號（`%@`、`%d` ...）順序帶入的參數。
    func localized(with arguments: CVarArg...) -> String {
        String(format: localized, arguments: arguments)
    }
}
