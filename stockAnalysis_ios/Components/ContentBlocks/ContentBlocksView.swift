//
//  ContentBlocksView.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/10.
//

import UIKit
import SnapKit

/// 把一串 `ContentBlock` 由上到下渲染成「自身可垂直捲動」的內容區。
///
/// 設計取捨（為什麼這樣做）：
/// - **自帶 ScrollView**：適合「上方控制項固定、只有內容區捲動」的版面（對照頁）。
///   若需要「整頁一起捲動」的場景（分析師個人頁的 sticky header），請改用 `ContentBlocksStackView`。
/// - **區塊建構共用**：實際的 markdown / table 堆疊交給 `ContentBlocksStackView`，本元件只負責捲動容器與空狀態。
/// - **只吃 `[ContentBlock]`**：與 model 解耦，對照頁、分析師頁皆可重用。
final class ContentBlocksView: UIView {

    /// 內容四周留白。
    private let contentInset = UIEdgeInsets(top: 16, left: 16, bottom: 24, right: 16)

    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        scroll.showsVerticalScrollIndicator = true
        return scroll
    }()

    /// 實際堆疊區塊的內容視圖（不捲動，由本元件的 ScrollView 負責捲動）。
    private let blocksStackView = ContentBlocksStackView()

    /// 無內容時顯示的空狀態文字（置中於整個元件，維持原本對照頁的視覺）。
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
        scrollView.addSubview(blocksStackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        blocksStackView.snp.makeConstraints { make in
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
    ///   - blocks: 要顯示的區塊；空陣列時顯示置中的 `emptyText`。
    ///   - emptyText: 無內容時的提示文字。
    func setBlocks(_ blocks: [ContentBlock], emptyText: String) {
        scrollView.setContentOffset(.zero, animated: false)

        emptyLabel.text = emptyText
        emptyLabel.isHidden = !blocks.isEmpty
        scrollView.isHidden = blocks.isEmpty
        guard !blocks.isEmpty else { return }

        blocksStackView.setBlocks(blocks, emptyText: emptyText)
    }
}
