//
//  DecodableTargetType.swift
//  WebService Core
//

import Foundation

/// 帶有「明確回應型別」的 Target。
///
/// 一支 API 的請求與它的回應型別是綁定的，把 `Response` 宣告在 Target 上之後，
/// `requestAsync` / `requestSingle` 等 helper 就能自動推導出要解碼成什麼型別，
/// 呼叫端不必再手動指定 `JSONDecoder().decode(SomeType.self, ...)`。
protocol DecodableTargetType: APITargetType {
    associatedtype Response: Decodable
}
