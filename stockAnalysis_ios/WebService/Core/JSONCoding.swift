//
//  JSONCoding.swift
//  WebService Core
//
//  專案統一的 JSON 編 / 解碼設定。集中於一處方便調整全域策略。
//

import Foundation

extension JSONDecoder {

    /// 專案統一使用的 JSONDecoder。
    ///
    /// 日期預設以毫秒 timestamp 解析；若後端改用 ISO8601 或其他格式，
    /// 只要改這裡即可全專案生效。
    class var `default`: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .millisecondsSince1970
        return decoder
    }
}

extension JSONEncoder {

    /// 與 `JSONDecoder.default` 對稱的編碼設定。
    class var `default`: JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .millisecondsSince1970
        return encoder
    }
}
