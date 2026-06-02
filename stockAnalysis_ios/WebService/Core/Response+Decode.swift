//
//  Response+Decode.swift
//  WebService Core
//
//  讓 Moya.Response / Single<Response> 能用專案統一的 JSONDecoder 解碼。
//

import Foundation
import Moya
import RxSwift

extension Moya.Response {

    /// 以專案統一的 `JSONDecoder.default` 將回應解碼為指定型別。
    /// - Parameters:
    ///   - type: 目標 Decodable 型別。
    ///   - keyPath: 若資料包在某個 key 底下（例如 `data`），可指定路徑。
    func decode<D: Decodable>(_ type: D.Type,
                              atKeyPath keyPath: String? = nil,
                              using decoder: JSONDecoder = .default,
                              failsOnEmptyData: Bool = true) throws -> D {
        return try map(type, atKeyPath: keyPath, using: decoder, failsOnEmptyData: failsOnEmptyData)
    }
}

extension PrimitiveSequence where Trait == SingleTrait, Element == Moya.Response {

    /// 在 Rx 串流中將回應解碼為指定型別；解碼失敗會送出 error。
    func decode<D: Decodable>(_ type: D.Type,
                              atKeyPath keyPath: String? = nil,
                              using decoder: JSONDecoder = .default,
                              failsOnEmptyData: Bool = true) -> Single<D> {
        return flatMap {
            .just(try $0.decode(type, atKeyPath: keyPath, using: decoder, failsOnEmptyData: failsOnEmptyData))
        }
    }
}
