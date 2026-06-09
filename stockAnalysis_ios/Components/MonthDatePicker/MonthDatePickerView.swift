//
//  MonthDatePickerView.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/9.
//

import UIKit
import SnapKit

/// 「月份下拉 + 日期膠囊」的可重用選擇器元件。
///
/// 設計取捨（為什麼這樣做）：
/// - **只吃 `[Date]`，不碰任何業務型別**：呼叫端（對照頁、分析師個人頁…）各自把資料解析成日期再餵進來，
///   元件內部負責「依年月分組、排序、產生月份選單與日期列」，因此任何頁面都能直接重用。
/// - **垂直方向自我撐高**：外部只需釘住 top / leading / trailing，高度由內部約束決定，呼叫端不必算高度。
/// - **自己找 presenter**：月份下拉用 `UIAlertController`（iOS 13 無 `UIMenu`），
///   透過 responder chain 找到所屬的 `UIViewController` 來 present，呼叫端不需額外接線。
/// - **語系可注入**：`locale` 預設跟隨 App 目前語系，但開放覆寫，方便測試或日後跨情境使用。
final class MonthDatePickerView: UIView {

    // MARK: - 對外 API

    /// 使用者點選某個日期時呼叫，帶回被選到的 `Date`。
    var onSelectDate: ((Date) -> Void)?

    /// 切換月份時呼叫（可選），帶回該月份的代表日（該月一號）。
    var onSelectMonth: ((Date) -> Void)?

    /// 月份標題顯示用的語系，預設跟隨 App 目前語系；可覆寫以利測試或其他情境。
    /// 設值後會即時刷新目前月份標題。
    var locale: Locale = LocalizationManager.shared.currentLanguage.locale {
        didSet { refreshMonthTitle() }
    }

    /// 月份下拉 actionSheet 的「取消」鍵文字，預設用 App 的本地化字串，可覆寫。
    var cancelButtonTitle: String = L10n.Common.cancel

    /// 是否有可顯示的資料（無資料時呼叫端可決定要不要把整個元件藏起來）。
    var isEmpty: Bool { monthSections.isEmpty }

    /// 餵入要顯示的日期清單（順序不限，內部會自行分組與排序）。
    /// 會依「年月」分組、月份與月內日期皆新到舊，並預設選取最新的月份與其最新一天。
    func setDates(_ dates: [Date]) {
        buildMonthSections(from: dates)
        applySelectedMonth(monthSections.first?.month)
    }

    // MARK: - 內部狀態

    /// 依「年月」分組後的資料，新到舊；每組帶該月所有日期（同樣新到舊）。
    private var monthSections: [(month: YearMonth, dates: [Date])] = []

    /// 目前選取的月份。
    private var selectedMonth: YearMonth?

    /// 解析/比較日期用的曆法，統一用公曆，避免受裝置曆法設定影響。
    private let calendar = Calendar(identifier: .gregorian)

    // MARK: - 子視圖

    /// 月份下拉選單（當作 Title）。點擊以 actionSheet 列出可選月份。
    private lazy var monthButton: UIButton = {
        let button = UIButton(type: .system)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .bold)
        button.setTitleColor(.label, for: .normal)
        button.tintColor = .label
        button.setImage(UIImage(systemName: "chevron.down"), for: .normal)
        // 預設 image 在文字左邊；用 forceRightToLeft 讓 chevron 移到文字右側，符合「標題 ▾」的視覺。
        button.semanticContentAttribute = .forceRightToLeft
        button.imageEdgeInsets = UIEdgeInsets(top: 0, left: 6, bottom: 0, right: 0)
        button.addTarget(self, action: #selector(didTapMonthButton), for: .touchUpInside)
        return button
    }()

    /// 月份下方的日期膠囊選擇列（水平可滑動）。
    private lazy var dateTabBar: DatePillTabBar = {
        let bar = DatePillTabBar()
        bar.onSelectDate = { [weak self] date in
            self?.onSelectDate?(date)
        }
        return bar
    }()

    // MARK: - 初始化與排版

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 內部垂直排版：月份下拉置中於上，日期膠囊列在下；整體高度由約束自我撐起。
    private func setupLayout() {
        addSubview(monthButton)
        addSubview(dateTabBar)

        monthButton.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.height.equalTo(32)
        }

        dateTabBar.snp.makeConstraints { make in
            make.top.equalTo(monthButton.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(36)
            make.bottom.equalToSuperview()
        }
    }

    // MARK: - 月份 / 日期推導

    /// 把傳入的日期依「年月」分組，建立 `monthSections`（月份與月內日期皆新到舊）。
    private func buildMonthSections(from dates: [Date]) {
        var grouped: [YearMonth: [Date]] = [:]
        for date in dates {
            let components = calendar.dateComponents([.year, .month], from: date)
            guard let year = components.year, let month = components.month else { continue }
            grouped[YearMonth(year: year, month: month), default: []].append(date)
        }

        monthSections = grouped
            .map { (month: $0.key, dates: $0.value.sorted(by: >)) }
            .sorted { $0.month > $1.month }
    }

    /// 套用選取的月份：更新標題、刷新日期膠囊列。
    /// 傳入 nil（無資料）時隱藏下拉與日期列，避免出現空白控制項。
    private func applySelectedMonth(_ month: YearMonth?) {
        selectedMonth = month

        guard let month = month,
              let section = monthSections.first(where: { $0.month == month }) else {
            monthButton.isHidden = true
            dateTabBar.isHidden = true
            return
        }

        monthButton.isHidden = false
        dateTabBar.isHidden = false
        refreshMonthTitle()
        dateTabBar.dates = section.dates

        // 切月時通知外部（帶該月一號當代表日）。
        if let representativeDate = calendar.date(from: DateComponents(year: month.year, month: month.month, day: 1)) {
            onSelectMonth?(representativeDate)
        }
    }

    /// 依目前 `selectedMonth` 與 `locale` 重新產生月份按鈕標題。
    private func refreshMonthTitle() {
        guard let month = selectedMonth else { return }
        monthButton.setTitle(monthTitle(for: month), for: .normal)
    }

    /// 把「年月」格式化成符合 `locale` 的標題，例如 zh：「2026年6月」、en：「June 2026」。
    private func monthTitle(for month: YearMonth) -> String {
        var components = DateComponents()
        components.year = month.year
        components.month = month.month
        guard let date = calendar.date(from: components) else { return "" }

        let formatter = DateFormatter()
        formatter.locale = locale
        // 用 template 讓「年月」的排列與寫法交給 locale 決定（中文年在前、英文月名在前）。
        formatter.setLocalizedDateFormatFromTemplate("yMMMM")
        return formatter.string(from: date)
    }

    // MARK: - 互動

    /// 點月份下拉：以 actionSheet 列出所有可選月份（iOS 13 相容做法）。
    @objc private func didTapMonthButton() {
        guard !monthSections.isEmpty, let presenter = owningViewController else { return }

        let actionSheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        for section in monthSections {
            let action = UIAlertAction(title: monthTitle(for: section.month), style: .default) { [weak self] _ in
                self?.applySelectedMonth(section.month)
            }
            actionSheet.addAction(action)
        }
        actionSheet.addAction(UIAlertAction(title: cancelButtonTitle, style: .cancel))

        // iPad 上 actionSheet 需要 anchor，否則會 crash；指向月份按鈕。
        if let popover = actionSheet.popoverPresentationController {
            popover.sourceView = monthButton
            popover.sourceRect = monthButton.bounds
        }
        presenter.present(actionSheet, animated: true)
    }

    /// 沿 responder chain 往上找出承載本 view 的 `UIViewController`，用來 present actionSheet。
    private var owningViewController: UIViewController? {
        var responder: UIResponder? = next
        while let current = responder {
            if let viewController = current as? UIViewController { return viewController }
            responder = current.next
        }
        return nil
    }
}
