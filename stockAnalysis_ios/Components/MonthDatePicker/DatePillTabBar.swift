//
//  DatePillTabBar.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/9.
//

import UIKit
import SnapKit

/// 水平可滑動的「日期膠囊」選擇列。
///
/// 設計取捨（為什麼這樣做）：
/// - **只負責呈現與選取，不碰資料來源**：外部把要顯示的 `[Date]` 餵進來、用 `onSelectDate` 接回選取結果，
///   元件本身不知道日期從哪來，因此可在任何頁面重用，也方便單獨寫測試。
/// - **用 UICollectionView 而非 UIStackView**：日期數量不固定（一個月可能十幾、二十筆），
///   collection view 內建重用與水平捲動，且選取狀態交由 cell 的 `isSelected` 管理，邏輯乾淨。
final class DatePillTabBar: UIView {

    /// 使用者點選某個日期時呼叫，帶回被選到的 `Date`。
    var onSelectDate: ((Date) -> Void)?

    /// 要顯示的日期清單；順序由外部決定（本專案是新到舊）。
    /// 設值會重載畫面，並預設選取第一個日期（若有），同時透過 `onSelectDate` 通知外部。
    /// 之所以連「預設選取」也通知：程式呼叫 `selectItem` 不會觸發 didSelectItemAt，
    /// 但外部（如載入對應日期的內容）需要在初次載入與換月時都拿到目前選中的日期。
    var dates: [Date] = [] {
        didSet {
            selectedDate = dates.first
            collectionView.reloadData()
            // 重載後預設選取第一個 cell。
            // 注意：scrollPosition 用空集合（不捲動）。第一顆本來就在最左（offset 0），
            // 若在此時要求 .left 捲動，因 collectionView 尚未完成 layout（bounds 為 0），
            // 位移會算錯而把第一顆捲出畫面。先確保回到最前面再選取。
            if let firstDate = dates.first {
                collectionView.setContentOffset(.zero, animated: false)
                let firstIndexPath = IndexPath(item: 0, section: 0)
                collectionView.selectItem(at: firstIndexPath, animated: false, scrollPosition: [])
                onSelectDate?(firstDate)
            }
        }
    }

    /// 目前選中的日期；無資料時為 nil。
    private(set) var selectedDate: Date?

    /// 膠囊上顯示的日期格式（固定 MM/dd，與語系無關，維持數字對齊好閱讀）。
    private static let pillDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "MM/dd"
        return formatter
    }()

    private static let cellIdentifier = "DatePillCell"

    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8   // 膠囊之間的水平間距
        layout.minimumInteritemSpacing = 8

        let collection = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collection.backgroundColor = .clear
        collection.showsHorizontalScrollIndicator = false
        collection.dataSource = self
        collection.delegate = self
        collection.register(DatePillCell.self, forCellWithReuseIdentifier: Self.cellIdentifier)
        // 讓膠囊左右留一點邊距，第一顆與最後一顆不會貼齊邊緣。
        collection.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)
        return collection
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        addSubview(collectionView)
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

// MARK: - UICollectionViewDataSource

extension DatePillTabBar: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        dates.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: Self.cellIdentifier, for: indexPath)
        if let pill = cell as? DatePillCell {
            pill.titleLabel.text = Self.pillDateFormatter.string(from: dates[indexPath.item])
        }
        return cell
    }
}

// MARK: - UICollectionViewDelegate

extension DatePillTabBar: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let date = dates[indexPath.item]
        selectedDate = date
        onSelectDate?(date)
    }
}

// MARK: - UICollectionViewDelegateFlowLayout

extension DatePillTabBar: UICollectionViewDelegateFlowLayout {

    /// 膠囊寬度依文字內容動態計算（文字寬 + 左右內距），高度填滿整列。
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let text = Self.pillDateFormatter.string(from: dates[indexPath.item])
        let textWidth = (text as NSString).size(withAttributes: [.font: DatePillCell.titleFont]).width
        let horizontalPadding: CGFloat = 16   // 單側內距，左右共 32
        let height = collectionView.bounds.height
        return CGSize(width: ceil(textWidth) + horizontalPadding * 2, height: height)
    }
}

// MARK: - DatePillCell

/// 單顆日期膠囊。未選取為淺灰底深色字，選取為紅底白字（依需求設計）。
private final class DatePillCell: UICollectionViewCell {

    static let titleFont = UIFont.systemFont(ofSize: 15, weight: .medium)

    let titleLabel: UILabel = {
        let label = UILabel()
        label.font = DatePillCell.titleFont
        label.textAlignment = .center
        return label
    }()

    /// 選取狀態切換時更新底色與文字色。
    override var isSelected: Bool {
        didSet { applySelectionStyle() }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)

        contentView.layer.cornerRadius = 16
        contentView.layer.masksToBounds = true
        contentView.addSubview(titleLabel)
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        applySelectionStyle()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // 高度可能隨外層列高變動，圓角取高度一半維持膠囊形狀。
        contentView.layer.cornerRadius = contentView.bounds.height / 2
    }

    private func applySelectionStyle() {
        if isSelected {
            contentView.backgroundColor = .systemRed
            titleLabel.textColor = .white
        } else {
            contentView.backgroundColor = UIColor.systemGray5
            titleLabel.textColor = .label
        }
    }
}
