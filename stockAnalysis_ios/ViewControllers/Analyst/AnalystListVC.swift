//
//  AnalystListVC.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/24.
//

import UIKit
import SnapKit

/// 分析師列表頁（Analyst Tab）：以卡片方式列出所有分析師，點卡片進入該分析師的個人頁。
///
/// 設計取捨：分析師數量少（目前四位）且固定，用 ScrollView + 垂直 StackView 直接堆卡片即可，
/// 不必動用 UICollectionView 的 cell 重用機制，與專案內其他自寫元件（ContentBlocksView）風格一致。
class AnalystListVC: UIViewController {

    /// 由 LoadingVC 載入後注入的股票分析資料。
    private var info: StockAnalysisInfo?

    /// 要顯示的分析師清單（缺漏時退回預設四位）。
    private lazy var analysts: [AnalystSummary] = AnalystSummary.makeList(from: info?.analysts)

    /// 卡片之間的垂直間距與整體留白。
    private let cardSpacing: CGFloat = 16
    private let contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        return scroll
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = cardSpacing
        return stack
    }()

    class func instantiate(info: StockAnalysisInfo? = nil) -> AnalystListVC {

        let viewController = AnalystListVC()
        viewController.info = info
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground
        setupLayout()
        populateCards()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 本頁是 TabBar 子頁，外層 NavigationBar 屬於 TabBarController。
        // 設 TabBarController 的 navigationItem.title 才會顯示在 NavigationBar，
        // 且不會像設 self.title 那樣污染底部 Tab 文字。每次切回本頁都會重設，確保標題正確。
        tabBarController?.navigationItem.title = L10n.Analyst.title
    }

    private func setupLayout() {
        view.addSubview(scrollView)
        scrollView.addSubview(stackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(view.safeAreaLayoutGuide)
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(contentInset)
            // 卡片寬度 = 捲動視窗寬度扣掉左右留白 → 只垂直捲動，不橫向。
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-(contentInset.left + contentInset.right))
        }
    }

    /// 依分析師清單建立卡片並接上點擊導頁。
    private func populateCards() {
        for summary in analysts {
            let card = AnalystCardView()
            card.configure(with: summary)
            card.onTap = { [weak self] in
                self?.showDetail(for: summary)
            }
            stackView.addArrangedSubview(card)
        }
    }

    /// 點卡片：push 該分析師的個人頁。
    /// 用外層 UINavigationController（TabBarController 被包在其中）來 push，並隱藏底部 TabBar 讓詳情頁更聚焦。
    private func showDetail(for summary: AnalystSummary) {
        let detailViewController = AnalystDetailVC.instantiate(summary: summary, info: info)
        detailViewController.hidesBottomBarWhenPushed = true
        navigationController?.pushViewController(detailViewController, animated: true)
    }
}
