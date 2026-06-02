//
//  AEMTargetError.swift
//  AE-MPS
//
//  Created by Hanyu on 2019/6/20.
//  Copyright © 2019 AE. All rights reserved.
//

import Foundation

struct WebAPIError: TargetError {
    
    // 不是 API 欄位的 msg，而是 WebAPIErrorTable 取出來的
    let message: String
    let code: Int
    let path: String
}

extension WebAPIError: LocalizedError {
    
    var errorDescription: String? {
        return message
    }
}

// MARK: - Getter
//extension WebAPIError {
//    
//    init?(method: String, path: String, code: Int) {
//
//        let dict = LanguageConfig.instance().currectLanguage
//
//        var key = "api__\(method.lowercased())_\(path)_\(code)"
//        if dict[key] != nil {
//            self.init(message: key.localized(), code: code, path: path)
//        } else {
//            key = "api__\(method.lowercased())_\(path)_general"
//            self.init(message: key.localized(), code: code, path: path)
//        }
//    }
//}
