//
//  MoyaProvider+Async.swift
//  WebService Core
//
//  async/await 介面。Moya 14 沒有原生 async，這裡用 continuation 橋接，
//  並透過 withTaskCancellationHandler 支援 Swift Concurrency 的 Task 取消。
//

import Foundation
import Moya

extension MoyaProvider where Target: DecodableTargetType {

    /// 送出請求並自動解碼為 `Target.Response`。
    /// - Note: 非 2xx 狀態碼會因 `validationType` 轉為錯誤丟出，呼叫端用 `try` 接住即可。
    func requestAsync(_ target: Target, decoder: JSONDecoder = .default) async throws -> Target.Response {
        let response = try await requestResponse(target)
        return try response.decode(Target.Response.self, using: decoder)
    }
}

extension MoyaProvider {

    /// 送出請求並回傳原始 `Moya.Response`（不解碼）。支援 Task 取消。
    func requestResponse(_ target: Target) async throws -> Moya.Response {
        let box = CancellableBox()
        return try await withTaskCancellationHandler {
            try await withCheckedThrowingContinuation { continuation in
                let token = self.request(target) { result in
                    continuation.resume(with: result)
                }
                box.store(token)
            }
        } onCancel: {
            box.cancel()
        }
    }
}

/// 包住 Moya 的 `Cancellable`，讓取消動作可跨 actor / thread 安全呼叫。
private final class CancellableBox: @unchecked Sendable {
    private let lock = NSLock()
    private var token: Moya.Cancellable?
    private var isCancelled = false

    func store(_ token: Moya.Cancellable) {
        lock.lock(); defer { lock.unlock() }
        // 若在拿到 token 前就被取消，這裡補上取消，避免請求繼續送出。
        if isCancelled {
            token.cancel()
        } else {
            self.token = token
        }
    }

    func cancel() {
        lock.lock(); defer { lock.unlock() }
        isCancelled = true
        token?.cancel()
    }
}
