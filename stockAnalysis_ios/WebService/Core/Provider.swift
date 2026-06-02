//
//  Provider.swift
//  WebService Core
//
//  MoyaProvider 的建立工廠。集中管理 session 設定、預設 plugin 與 stub 切換。
//

import Moya
import Alamofire

extension MoyaProvider {

    /// 預設 Provider：15 秒逾時、含磁碟快取與錯誤轉換 plugin。
    /// 一般 API 直接用這個即可。
    class var `default`: MoyaProvider<Target> {
        return make(cache: CacheConfig.default)
    }

    /// 建立 Provider 的統一入口。
    ///
    /// - Parameters:
    ///   - cache: 傳入 `URLCache` 則啟用快取（並掛上 `CachePlugin`）；傳 `nil` 則不快取。
    ///   - extraPlugins: 各專案可額外注入的 plugin（例如 `AccessTokenPlugin`、Log plugin）。
    ///
    /// 若環境變數 `STUB == "true"`，一律回傳 `stubProvider`，方便 UITest / 開發期離線測試。
    class func make(cache: URLCache? = nil,
                    extraPlugins: [PluginType] = []) -> MoyaProvider<Target> {

        if ProcessInfo.processInfo.environment["STUB"] == "true" {
            return stubProvider
        }

        var plugins: [PluginType] = [ErrorTransformerPlugin()]
        if cache != nil {
            // 順序有差：CachePlugin 需在送出前調整 cachePolicy ⚠️
            plugins.append(CachePlugin())
        }
        plugins.append(contentsOf: extraPlugins)

        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 15.0
        configuration.requestCachePolicy = .reloadIgnoringLocalAndRemoteCacheData
        if let cache = cache {
            configuration.urlCache = cache
        }
        // startRequestsImmediately = false：交給 Moya 自行 resume，避免重複觸發。
        let session = Session(configuration: configuration, startRequestsImmediately: false)

        return MoyaProvider<Target>(session: session, plugins: plugins)
    }

    /// 以 sampleData 回應的測試用 Provider（延遲 0.2 秒模擬網路）。
    class var stubProvider: MoyaProvider<Target> {
        return MoyaProvider<Target>(
            stubClosure: MoyaProvider<Target>.delayedStub(0.2),
            plugins: [ErrorTransformerPlugin()]
        )
    }
}
