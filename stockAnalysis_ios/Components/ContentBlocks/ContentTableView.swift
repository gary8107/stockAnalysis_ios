//
//  ContentTableView.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/10.
//

import UIKit
import SnapKit

/// 可水平捲動的表格網格（表頭 + 多列資料）。
///
/// 設計取捨（為什麼這樣做）：
/// - **欄寬固定、整體可左右捲動**：對照表常有 5~6 欄密集中文，固定欄寬維持每格可讀寬度，
///   超出畫面就靠水平捲動，而不是硬塞進螢幕寬度造成每格過窄、列高暴增。
/// - **不做內部垂直捲動**：整個表格依內容撐到實際高度，垂直捲動交給外層頁面，避免巢狀捲動打架。
/// - **純資料輸入（headers / rows）**：不認得任何 model，任何頁面都能重用。
/// - 儲存格文字會走 `MarkdownRenderer` 的行內格式（格子內也有 `**粗體**`）。
final class ContentTableView: UIView {

    /// 第一欄（通常是列標題，如「項目」「老師」）寬度，較窄。
    private let firstColumnWidth: CGFloat = 110
    /// 其餘資料欄寬度，較寬以容納密集內容。
    private let dataColumnWidth: CGFloat = 200
    /// 儲存格內距。
    private let cellInset = UIEdgeInsets(top: 8, left: 10, bottom: 8, right: 10)

    // 字級依使用者選擇的字體大小倍率縮放（見 TextSizeManager）。
    // 用 instance let 在「建立此表格時」讀取倍率即可——字級切換後會重建畫面、產生新的表格實例。
    private let cellFont = UIFont.systemFont(ofSize: 13 * TextSizeManager.shared.scale)
    private let headerFont = UIFont.systemFont(ofSize: 13 * TextSizeManager.shared.scale, weight: .bold)

    /// 水平捲動容器。
    private let scrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.showsHorizontalScrollIndicator = true
        scroll.showsVerticalScrollIndicator = false
        scroll.bounces = false
        return scroll
    }()

    /// 由上到下排列每一列。
    private let rowsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.alignment = .fill
        stack.spacing = 0
        return stack
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        // 整張表外圍包一層分隔線色，當作格線底色透出來。
        backgroundColor = .separator
        layer.cornerRadius = 8
        layer.masksToBounds = true

        addSubview(scrollView)
        scrollView.addSubview(rowsStackView)

        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        rowsStackView.snp.makeConstraints { make in
            make.edges.equalTo(scrollView.contentLayoutGuide)
            // 高度等於 frame 高度 → 不產生垂直捲動，表格依內容自我撐高。
            make.height.equalTo(scrollView.frameLayoutGuide)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 餵入表格資料並重建畫面。
    /// - Parameters:
    ///   - headers: 表頭文字。
    ///   - rows: 每列的儲存格文字；欄數不足會以空字串補齊，避免欄位錯位。
    func setData(headers: [String], rows: [[String]]) {
        rowsStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }

        let columnCount = max(headers.count, rows.map(\.count).max() ?? 0)
        guard columnCount > 0 else { return }

        // 表頭列。
        rowsStackView.addArrangedSubview(makeRow(cells: headers, columnCount: columnCount, isHeader: true))

        // 資料列（交錯底色提升可讀性）。
        for (index, row) in rows.enumerated() {
            let backgroundColor: UIColor = index % 2 == 0 ? .systemBackground : .secondarySystemBackground
            rowsStackView.addArrangedSubview(makeRow(cells: row, columnCount: columnCount, isHeader: false, backgroundColor: backgroundColor))
        }
    }

    // MARK: - 建構列與儲存格

    /// 建一整列（水平排列各欄儲存格）。
    private func makeRow(cells: [String], columnCount: Int, isHeader: Bool, backgroundColor: UIColor = .systemBackground) -> UIView {
        let rowStack = UIStackView()
        rowStack.axis = .horizontal
        rowStack.alignment = .fill   // 所有儲存格拉到同列高，欄線才會對齊
        rowStack.distribution = .fill
        rowStack.spacing = 0

        for column in 0..<columnCount {
            let text = column < cells.count ? cells[column] : ""
            let width = column == 0 ? firstColumnWidth : dataColumnWidth
            rowStack.addArrangedSubview(makeCell(text: text, width: width, isHeader: isHeader, backgroundColor: backgroundColor))
        }
        return rowStack
    }

    /// 建單一儲存格：固定寬度、可換行、內距、底色與 hairline 格線。
    private func makeCell(text: String, width: CGFloat, isHeader: Bool, backgroundColor: UIColor) -> UIView {
        let container = UIView()
        container.backgroundColor = isHeader ? .tertiarySystemBackground : backgroundColor
        // 用每格的細邊框當格線；相鄰格共用邊看起來即是一張網格。
        container.layer.borderWidth = 0.5
        container.layer.borderColor = UIColor.separator.cgColor
        container.snp.makeConstraints { make in
            make.width.equalTo(width)
        }

        let label = UILabel()
        label.numberOfLines = 0
        let font = isHeader ? headerFont : cellFont
        label.attributedText = MarkdownRenderer.inlineAttributedString(from: text, font: font)
        container.addSubview(label)
        label.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(cellInset)
        }
        return container
    }
}
