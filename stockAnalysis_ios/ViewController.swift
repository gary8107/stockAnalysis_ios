//
//  ViewController.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/1.
//

import UIKit
import RxSwift

class ViewController: UIViewController {

    private let viewModel = StockAnalysisViewModel()
    private let disposeBag = DisposeBag()

    override func viewDidLoad() {
        super.viewDidLoad()
        bindViewModel()
        viewModel.load()
    }

    /// 將 ViewModel 的狀態綁定到畫面更新。
    private func bindViewModel() {
        viewModel.state
            .observeOn(MainScheduler.instance)
            .subscribe(onNext: { [weak self] state in
                self?.render(state)
            })
            .disposed(by: disposeBag)
    }

    private func render(_ state: LoadingState<StockAnalysisInfo>) {
        switch state {
        case .idle:
            break
        case .loading:
            print("loading…")
        case .loaded(let info):
            print("loaded: \(info.notes?.count ?? 0) notes, \(info.analysts?.count ?? 0) analysts")
        case .failed(let error):
            print("failed: \(error.localizedDescription)")
        }
    }
}
