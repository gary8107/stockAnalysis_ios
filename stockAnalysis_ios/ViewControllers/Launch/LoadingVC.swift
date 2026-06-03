//
//  LoadingVC.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/3.
//

import UIKit
import RxSwift

class LoadingVC: UIViewController {
    
    private let viewModel = StockAnalysisViewModel()
    private let disposeBag = DisposeBag()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print("loadingVC")
        self.getStockInfo()
    }
    
    func getStockInfo() {
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
            showHome(with: info)

        case .failed(let error):
            print("failed: \(error.localizedDescription)")
        }
    }

    /// 資料載入完成後切換到首頁（三個 Tab 的 TabBarController）。
    ///
    /// 用「替換 window 的 rootViewController」而非 `present`：
    /// Loading 只是過場畫面，不應該留在導航堆疊裡讓使用者能返回，
    /// 直接換掉 root 可釋放 LoadingVC 並讓首頁成為新的起點。
    private func showHome(with info: StockAnalysisInfo) {
        guard let window = view.window else { return }

        let homeViewController = MainNavigationController.instantiate(info: info)
        window.rootViewController = homeViewController

        // 加上淡入轉場，避免切換 root 時畫面硬切顯得突兀。
        UIView.transition(with: window,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: nil,
                          completion: nil)
    }
}
