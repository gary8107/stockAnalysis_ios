//
//  StockAnalysisRepository.swift
//
//  Repository 層：把「呼叫哪支 API、用哪個 Provider」收斂在一起，
//  對上層（ViewModel）只暴露語意化的方法。
//
//  好處：
//  - ViewModel 不直接碰 Moya / Provider，方便替換與測試。
//  - 透過 protocol 注入，測試時可塞假的 Repository。
//

import Foundation
import Moya
import RxSwift

// 縮短巢狀型別名稱，提升可讀性。
typealias StockAnalysisInfo = StockAnalysisService.GetStockAnalysis.StockAnalysisInfo
typealias StockAnalysisQuery = StockAnalysisService.GetStockAnalysis.Query
typealias AnalystComparison = StockAnalysisService.GetStockAnalysis.Comparison
typealias Analyst = StockAnalysisService.GetStockAnalysis.Analyst
typealias AnalystNote = StockAnalysisService.GetStockAnalysis.Note
typealias AnalysisBlock = StockAnalysisService.GetStockAnalysis.Block
typealias AnalysisBlockType = StockAnalysisService.GetStockAnalysis.BlockType

/// 提供個股分析資料的抽象介面。
protocol StockAnalysisRepositoryType {
    /// async/await 版本。
    func fetchStockInfo(query: StockAnalysisQuery) async throws -> StockAnalysisInfo
    /// RxSwift 版本。
    func fetchStockInfo(query: StockAnalysisQuery) -> Single<StockAnalysisInfo>
}

// 讓 query 可省略。
extension StockAnalysisRepositoryType {
    func fetchStockInfo() async throws -> StockAnalysisInfo {
        try await fetchStockInfo(query: .init())
    }
    func fetchStockInfo() -> Single<StockAnalysisInfo> {
        fetchStockInfo(query: .init())
    }
}

final class StockAnalysisRepository: StockAnalysisRepositoryType {

    private let provider: MoyaProvider<StockAnalysisService.GetStockAnalysis>

    /// Provider 以注入方式提供，預設用 `.default`；測試時可傳入 `.stubProvider`。
    init(provider: MoyaProvider<StockAnalysisService.GetStockAnalysis> = .default) {
        self.provider = provider
    }

    func fetchStockInfo(query: StockAnalysisQuery) async throws -> StockAnalysisInfo {
        try await provider.requestAsync(.init(query))
    }

    func fetchStockInfo(query: StockAnalysisQuery) -> Single<StockAnalysisInfo> {
        provider.requestSingle(.init(query))
    }
}
