//
//  AnalystVC.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/3.
//

import UIKit

class AnalystVC: UIViewController {

    /// 由 LoadingVC 載入後注入的股票分析資料。
    private var info: StockAnalysisInfo?

    /// 畫面中央的說明文字：有資料時顯示人數摘要，沒有時顯示空狀態文案。
    /// 目前頁面內容尚未實作，先用它把 L10n 接上並驗證多語系顯示。
    private let summaryLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        label.textColor = .secondaryLabel
        return label
    }()

    class func instantiate(info: StockAnalysisInfo? = nil) -> AnalystVC {

        let viewController = AnalystVC()
        viewController.info = info
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupSummaryLabel()
        applyLocalizedTexts()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 設外層 NavigationBar（屬於 TabBarController）的標題；不用 self.title 以免污染底部 Tab 文字。
        tabBarController?.navigationItem.title = L10n.Analyst.title
    }

    private func setupSummaryLabel() {
        view.addSubview(summaryLabel)
        summaryLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            summaryLabel.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            summaryLabel.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            summaryLabel.leadingAnchor.constraint(greaterThanOrEqualTo: view.leadingAnchor, constant: 24),
            summaryLabel.trailingAnchor.constraint(lessThanOrEqualTo: view.trailingAnchor, constant: -24),
        ])
    }

    /// 套用目前語系的本地化文字。
    /// 抽成獨立方法，讓「進入畫面」與未來「語系切換後刷新」能共用同一段邏輯。
    private func applyLocalizedTexts() {
        // 有分析師資料就顯示帶人數的摘要，否則顯示空狀態文案。
        let analysts = info?.analysts ?? []
        summaryLabel.text = analysts.isEmpty
            ? L10n.Analyst.empty
            : L10n.Analyst.summary(count: analysts.count)
    }
}
