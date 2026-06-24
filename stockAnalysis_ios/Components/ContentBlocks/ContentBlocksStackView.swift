//
//  ContentBlocksStackView.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/24.
//

import UIKit
import SnapKit

/// 把一串 `ContentBlock` 由上到下堆成「會隨內容撐高」的垂直區塊視圖（本身**不捲動**）。
///
/// 設計取捨（為什麼要有這個、跟 `ContentBlocksView` 差在哪）：
/// - `ContentBlocksView` 自帶 ScrollView，適合「內容區自己捲動、上方控制項固定」的版面（對照頁）。
/// - 但分析師個人頁要做「整頁一起捲動、日期列 sticky 釘頂」的效果，內容必須跟著外層 ScrollView 捲，
///   若再包一層自己的 ScrollView 會變成巢狀捲動。故抽出這個無 ScrollView、靠約束自我撐高的版本，
///   讓呼叫端把它直接放進自己的 ScrollView。
/// - 區塊建構邏輯（markdown / table）集中在這裡，`ContentBlocksView` 內部也改用它，避免重複。
final class ContentBlocksStackView: UIView {

    /// 區塊之間的垂直間距。
    private let blockSpacing: CGFloat = 16

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = blockSpacing
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(stackView)
        // stackView 釘滿四邊，整個視圖高度便由堆疊內容決定（無 ScrollView）。
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    /// 餵入區塊資料並重建內容。
    /// - Parameters:
    ///   - blocks: 要顯示的區塊；空陣列時改放一個置中的 `emptyText` 標籤。
    ///   - emptyText: 無內容時的提示文字。
    func setBlocks(_ blocks: [ContentBlock], emptyText: String) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        guard !blocks.isEmpty else {
            stackView.addArrangedSubview(makeEmptyLabel(emptyText))
            return
        }

        for block in blocks {
            switch block {
            case .markdown(let text):
                stackView.addArrangedSubview(makeMarkdownLabel(text))
            case .table(let headers, let rows):
                stackView.addArrangedSubview(makeTableView(headers: headers, rows: rows))
            }
        }
    }

    // MARK: - 建構區塊視圖

    private func makeEmptyLabel(_ text: String) -> UIView {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        return label
    }

    private func makeMarkdownLabel(_ markdown: String) -> UIView {
        let label = UILabel()
        label.numberOfLines = 0
        label.attributedText = MarkdownRenderer.attributedString(from: markdown)
        return label
    }

    private func makeTableView(headers: [String], rows: [[String]]) -> UIView {
        let tableView = ContentTableView()
        tableView.setData(headers: headers, rows: rows)
        return tableView
    }
}
