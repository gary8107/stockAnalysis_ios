//
//  ContentBlocksView.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/10.
//

import UIKit
import SnapKit

/// 把一串 `ContentBlock` 由上到下渲染成可垂直捲動的內容區。
///
/// 設計取捨（為什麼這樣做）：
/// - **垂直捲動 + UIStackView**：區塊型別異質且數量不定（markdown 段落與表格交錯），
///   用 ScrollView + StackView 依序堆疊最直接，不必像 UITableView 處理多種 cell 與巢狀捲動。
/// - **只吃 `[ContentBlock]`**：與 model 解耦，對照頁、分析師頁皆可重用。
final class ContentBlocksView: UIView {

    /// 區塊之間的垂直間距。
    private let blockSpacing: CGFloat = 16
    /// 內容四周留白。
    private let contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = true
        return scroll
    }()

    private lazy var stackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = blockSpacing
        return stack
    }()

    /// 無內容時顯示的空狀態文字。
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.textColor = .secondaryLabel
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        addSubview(scrollView)
        addSubview(emptyLabel)
        scrollView.addSubview(stackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        stackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide).inset(contentInset)
            // 內容寬度 = 捲動視窗寬度扣掉左右留白 → 只垂直捲動，不橫向。
            make.width.equalTo(scrollView.frameLayoutGuide).offset(-(contentInset.left + contentInset.right))
        }
        emptyLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(24)
        }
    }

    /// 餵入區塊資料並重建內容。
    /// - Parameters:
    ///   - blocks: 要顯示的區塊；空陣列時顯示 `emptyText`。
    ///   - emptyText: 無內容時的提示文字。
    func setBlocks(_ blocks: [ContentBlock], emptyText: String) {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        scrollView.setContentOffset(.zero, animated: false)

        emptyLabel.text = emptyText
        emptyLabel.isHidden = !blocks.isEmpty
        scrollView.isHidden = blocks.isEmpty
        guard !blocks.isEmpty else { return }

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
