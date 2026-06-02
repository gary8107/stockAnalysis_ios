//
//  APITargetType.swift
//  WebService Core
//
//  專案統一的 Moya TargetType。
//  各支 API 只要 conform 此協定，即可取得共用的預設值（header、驗證碼、sampleData）。
//

import Foundation
import Moya

/// 本專案所有 API 的共通 TargetType。
///
/// 設計重點：
/// - **不在此處寫死 `baseURL`**：host 屬於各專案 / 各環境的設定，由具體的 Target 自行提供，
///   這樣整包 Core 才能直接搬到其他專案使用。
/// - 提供合理的預設 `headers`、`validationType`、`sampleData`，減少每支 API 的樣板程式碼。
protocol APITargetType: TargetType {}

extension APITargetType {

    /// 2xx 視為成功，其餘狀態碼一律轉為錯誤，交由 `ErrorTransformerPlugin` / 呼叫端處理。
    var validationType: ValidationType {
        return .successCodes
    }

    var headers: [String: String]? {
        return ["Content-Type": "application/json"]
    }

    /// 預設提供空 sampleData；需要用 stub 做測試的 Target 再自行覆寫。
    var sampleData: Data {
        return Data()
    }
}

// MARK: - Access Token

/// 需要帶 Bearer Token 的 API 可額外 conform 此協定。
/// Token 的實際注入由建立 Provider 時掛上的 `AccessTokenPlugin` 負責。
protocol APIAccessTokenAuthorizable: AccessTokenAuthorizable {}

extension APIAccessTokenAuthorizable {
    var authorizationType: AuthorizationType? { return .bearer }
}
