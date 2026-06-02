//
//  StockAnalysisViewModel.swift
//
//  MVVM 的 ViewModel：負責業務邏輯與狀態管理，不持有任何 UIKit 元件。
//  對 View 只暴露可觀察的 `state`，View 訂閱後依狀態更新畫面。
//

import Foundation
import RxSwift
import RxRelay

final class StockAnalysisViewModel {

    /// 對外的 UI 狀態，View 訂閱此 relay 來更新畫面。
    let state = BehaviorRelay<LoadingState<StockAnalysisInfo>>(value: .idle)

    private let repository: StockAnalysisRepositoryType
    private let disposeBag = DisposeBag()

    /// Repository 以注入方式提供，預設用正式實作；測試時可塞假的。
    init(repository: StockAnalysisRepositoryType = StockAnalysisRepository()) {
        self.repository = repository
    }

    /// 載入個股分析資料（RxSwift 版本）。
    func load(query: StockAnalysisQuery = .init()) {
        state.accept(.loading)

        repository.fetchStockInfo(query: query)
            .observeOn(MainScheduler.instance)
            .subscribe(
                onSuccess: { [weak self] info in
                    self?.state.accept(.loaded(info))
                },
                onError: { [weak self] error in
                    self?.state.accept(.failed(error))
                }
            )
            .disposed(by: disposeBag)
    }

    // MARK: - async/await 版本（擇一使用即可）
    //
    // 若 View 端改用 async，可改呼叫這個方法：
    //
    // func load(query: StockAnalysisQuery = .init()) async {
    //     state.accept(.loading)
    //     do {
    //         let info = try await repository.fetchStockInfo(query: query)
    //         state.accept(.loaded(info))
    //     } catch {
    //         state.accept(.failed(error))
    //     }
    // }
}
