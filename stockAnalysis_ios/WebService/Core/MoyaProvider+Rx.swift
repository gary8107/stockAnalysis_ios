//
//  MoyaProvider+Rx.swift
//  WebService Core
//
//  RxSwift 介面。對既有大量使用 RxSwift 的專案保留熟悉的 Single 寫法。
//

import Foundation
import Moya
import RxSwift

extension MoyaProvider where Target: DecodableTargetType {

    /// 送出請求並自動解碼為 `Target.Response`，回傳 `Single`。
    /// - Note: 非 2xx 狀態碼會因 `validationType` 轉為 error event，
    ///   呼叫端用 `onFailure` 接住即可。
    func requestSingle(_ target: Target, decoder: JSONDecoder = .default) -> Single<Target.Response> {
        return rx.request(target)
            .decode(Target.Response.self, using: decoder)
    }
}
