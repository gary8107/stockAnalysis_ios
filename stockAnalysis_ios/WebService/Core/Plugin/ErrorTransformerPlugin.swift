//
//  TransformerPlugin.swift
//  AECastle
//
//  Created by Kao Ming-Hsiu on 2019/3/28.
//  Copyright © 2019 Gary.Lin. All rights reserved.
//

import Moya
import enum Alamofire.AFError

/// 處理 StatusCode 錯誤, 轉為 MoyaError.underlying(APIException, Response)
class ErrorTransformerPlugin: PluginType {
    func process(_ result: Result<Moya.Response, MoyaError>, target: TargetType) -> Result<Response, MoyaError> {
        
        guard case let Result.failure(moyaError) = result else { return result }
        guard let response = moyaError.response else { return result }
        
        switch moyaError {
        case let MoyaError.underlying(afError as AFError, _):
            guard case AFError.responseValidationFailed(reason: _) = afError else {
                return result
            }
        case let MoyaError.underlying(e as MoyaError, _):
            guard case MoyaError.statusCode(_) = e else {
                return result
            }
        case MoyaError.statusCode(_):
            break
        default:
            return result
        }
        if let apiException = try? JSONDecoder().decode(APIException.self, from: response.data) {
            guard case let APIException.unDocumentedMessage(raw) = apiException, let taregetError = (target as? TargetErrorProviderType)?.targetError(from: apiException) else {
                return Result.failure(MoyaError.underlying(apiException, response))
            }
            return Result.failure(MoyaError.underlying(APIException.targetError(error: taregetError, raw: raw), response))
        }
        
        return result
    }
}

/// TargetError： 將「API Path」與「後端自訂 Error Code」對應出的錯誤類型（協定）
protocol TargetError: Error {

    /// 後端自訂錯誤碼
    var code: Int {get}
    /// Target Path
    var path: String {get}
}

/// 賦予 ErrorTransformerPlugin 將「API Path」與「後端自訂 Error Code」對應為「TargetError」，並存放於 case APIException.targetError 內能力的協定
protocol TargetErrorProviderType where Self: TargetType {
    /// TargetError mapping function.
    ///
    /// - Parameter exception: 傳入 APIException
    /// - Returns: 轉換錯誤，成功就返回一 TargetError
    func targetError(from exception: APIException) -> TargetError?
}

// MARK: - shortcut
extension APIException {
    var targetError: TargetError? {
        guard case let APIException.targetError(error, _) = self else {return nil}
        return error
    }
}

// MARK: - shortcut
extension MoyaError {
    var targetError: TargetError? {
        guard case let MoyaError.underlying(error as APIException, _) = self else { return nil }
        return error.targetError
    }
}

/// API 回應的任何錯誤定義在這裡
///
/// - targetError: 於 Target 中定義的錯誤
/// - unDocumentedMessage: {"msg": "123 error message", "code": 123}
/// - plainText: "any text"
enum APIException: Decodable, Error, LocalizedError {
    
    case unDocumentedMessage(code: Int, message: String)
    case targetError(error: TargetError, raw: (Int, String))
    case plainText(String)
    
    /// 錯誤的 json 有哪些key
    private enum ErrorResponseCodingKeys: String, CodingKey {
        case message = "msg"
        case code
        case replace
    }
    
    init(from decoder: Decoder) throws {
        
        let container = try decoder.container(keyedBy: ErrorResponseCodingKeys.self)
        
        let code = try container.decode(Int.self, forKey: .code)
        
        if let message = try? container.decode(String?.self, forKey: .message) {
            self = .unDocumentedMessage(code: code, message: message)
            return
        } else {
           // 因為 api 回傳錯誤中：有 code 但 msg 為 null 會decode 失敗，所以另外處理
            do {
               let msg = try container.decode(String?.self, forKey: .message)
                self = .unDocumentedMessage(code: code, message: "")
            } catch {
                self = .plainText(try decoder.singleValueContainer().decode(String?.self) ?? "")
            }
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .plainText(let error):
            return error
        case .unDocumentedMessage(let code, let message):
            return "Error code: \(code)" + "\n" + "Error message: \(message)"
        case .targetError(let targetError, _):
            return targetError.localizedDescription
        }
    }
    
    var code: Int? {
        switch self {
        case .plainText:
            return nil
        case .unDocumentedMessage(let code, _):
            return code
        case .targetError(_, let raw):
            return raw.0
        }
    }
    
    var message: String {
        switch self {
        case .plainText(let text):
            return text
        case .targetError(error: _, let raw):
            return raw.1
        case .unDocumentedMessage(_, let message):
            return message
        }
    }
}
