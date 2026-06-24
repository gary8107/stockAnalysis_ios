//
//  SettingVC.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/3.
//

import UIKit

/// 設定頁。以 `.insetGrouped` 分組表格提供：
/// 1. 外觀模式（深 / 淺 / 跟隨系統）— 即時套用，不需重建。
/// 2. 字體大小 — 影響內容文字，切換後重建首頁套用。
/// 3. 語言 — 切換後重建首頁刷新全畫面。
/// 4. 資料訊息 — 唯讀顯示最後更新時間與各類資料數量。
/// 5. 關於 — App 版本、原始碼位置（點擊開啟 GitHub）、App 介紹。
final class SettingVC: UIViewController {

    /// App 原始碼位置（取自專案 git remote）。
    private static let sourceURL = URL(string: "https://github.com/gary8107/stockAnalysis_ios")!

    /// 由 LoadingVC 載入後一路注入到此的股票分析資料。
    /// 切換語系 / 字體需要重建首頁，重建時要把同一份資料再傳下去，所以這裡要持有。
    private var info: StockAnalysisInfo?

    /// 設定頁的區塊順序。
    private enum Section: CaseIterable {
        case appearance
        case textSize
        case language
        case data
        case about
    }

    /// 資料訊息區的列。
    private enum DataRow: Int, CaseIterable {
        case lastUpdate
        case analysts
        case notes
        case comparisons
    }

    /// 關於區的列（介紹文字放在 section footer，不佔列）。
    private enum AboutRow: Int, CaseIterable {
        case version
        case source
    }

    private let sections = Section.allCases
    private let appearances = AppAppearance.allCases
    private let textSizes = AppTextSize.allCases
    private let languages = AppLanguage.allCases

    private lazy var tableView: UITableView = {
        // 用 .insetGrouped 取得 iOS 設定 App 那種分組外觀，並能顯示 section 標題與說明文字。
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        return tableView
    }()

    /// 一般選項列（含勾選）用的識別碼。
    private static let optionCellIdentifier = "OptionCell"
    /// 「標題 + 右側數值」列（資料訊息、版本）用的識別碼。
    private static let valueCellIdentifier = "ValueCell"

    class func instantiate(info: StockAnalysisInfo? = nil) -> SettingVC {
        let viewController = SettingVC()
        viewController.info = info
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground
        setupTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 設外層 NavigationBar（屬於 TabBarController）的標題；不用 self.title 以免污染底部 Tab 文字。
        tabBarController?.navigationItem.title = L10n.Setting.title
    }

    private func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: view.topAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
        ])
    }

    // MARK: - Cell 工廠

    /// 取得一般選項列（左文字 + 可選勾選）。
    private func optionCell(text: String, checked: Bool) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.optionCellIdentifier)
            ?? UITableViewCell(style: .default, reuseIdentifier: Self.optionCellIdentifier)
        // 部署目標 iOS 13，沿用傳統 textLabel API（defaultContentConfiguration 需 iOS 14+）。
        cell.textLabel?.text = text
        cell.textLabel?.textColor = .label
        cell.accessoryType = checked ? .checkmark : .none
        cell.selectionStyle = .default
        return cell
    }

    /// 取得「標題 + 右側數值」列。`selectable` 決定是否可點擊（可點時加上揭示箭頭）。
    private func valueCell(title: String, value: String?, selectable: Bool) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.valueCellIdentifier)
            ?? UITableViewCell(style: .value1, reuseIdentifier: Self.valueCellIdentifier)
        cell.textLabel?.text = title
        cell.detailTextLabel?.text = value
        cell.accessoryType = selectable ? .disclosureIndicator : .none
        cell.selectionStyle = selectable ? .default : .none
        return cell
    }

    // MARK: - 資料訊息 / 版本格式化

    /// 把 `generated_at`（ISO8601，可能帶毫秒）格式化成目前語系的「日期 + 時間」。
    private func formattedLastUpdate() -> String {
        guard let raw = info?.generatedAt, !raw.isEmpty else { return L10n.Setting.dataNoValue }

        // 先嘗試帶毫秒，失敗再退回不帶毫秒的標準格式。
        let withFraction = ISO8601DateFormatter()
        withFraction.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        let plain = ISO8601DateFormatter()
        plain.formatOptions = [.withInternetDateTime]

        guard let date = withFraction.date(from: raw) ?? plain.date(from: raw) else {
            return raw // 解析不出來就原樣顯示，至少不漏資訊。
        }

        let formatter = DateFormatter()
        formatter.locale = LocalizationManager.shared.currentLanguage.locale
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// 取資料各類數量的字串；無資料顯示 0。
    private func dataValue(for row: DataRow) -> String {
        switch row {
        case .lastUpdate: return formattedLastUpdate()
        case .analysts: return String(info?.analysts?.count ?? 0)
        case .notes: return String(info?.notes?.count ?? 0)
        case .comparisons: return String(info?.comparisons?.count ?? 0)
        }
    }

    private func dataTitle(for row: DataRow) -> String {
        switch row {
        case .lastUpdate: return L10n.Setting.dataLastUpdate
        case .analysts: return L10n.Setting.dataAnalysts
        case .notes: return L10n.Setting.dataNotes
        case .comparisons: return L10n.Setting.dataComparisons
        }
    }

    /// App 版本字串，例如「1.0 (1)」。
    private func appVersionText() -> String {
        let dictionary = Bundle.main.infoDictionary
        let shortVersion = dictionary?["CFBundleShortVersionString"] as? String ?? "—"
        let build = dictionary?["CFBundleVersion"] as? String ?? "—"
        return "\(shortVersion) (\(build))"
    }

    // MARK: - 動作

    /// 切換外觀模式：即時套用（window override 會自帶平滑轉場），只需刷新勾選狀態。
    private func selectAppearance(_ appearance: AppAppearance) {
        AppearanceManager.shared.setAppearance(appearance)
        tableView.reloadSections(IndexSet(integer: sectionIndex(of: .appearance)), with: .none)
    }

    /// 切換字體大小：持久化後重建首頁，讓內容以新字級重新渲染。
    private func selectTextSize(_ size: AppTextSize) {
        guard size != TextSizeManager.shared.current else { return }
        TextSizeManager.shared.setTextSize(size)
        rebuildHome()
    }

    /// 切換語系：透過 LocalizationManager 更新（持久化並發通知），再重建首頁刷新全畫面。
    private func switchLanguage(to language: AppLanguage) {
        guard language != LocalizationManager.shared.currentLanguage else { return }
        LocalizationManager.shared.setLanguage(language)
        rebuildHome()
    }

    /// 重建首頁並停回設定頁（語系 / 字體切換共用）。
    private func rebuildHome() {
        let home = AppRootBuilder.makeHome(info: info, selectedTab: .setting)
        AppRootBuilder.switchRoot(to: home, in: view.window)
    }

    /// 開啟原始碼位置（外部 Safari）。
    private func openSourceCode() {
        UIApplication.shared.open(Self.sourceURL)
    }

    /// 取得某個 Section 在目前順序中的索引。
    private func sectionIndex(of section: Section) -> Int {
        sections.firstIndex(of: section) ?? 0
    }
}

// MARK: - UITableViewDataSource

extension SettingVC: UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .appearance: return appearances.count
        case .textSize: return textSizes.count
        case .language: return languages.count
        case .data: return DataRow.allCases.count
        case .about: return AboutRow.allCases.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .appearance:
            let appearance = appearances[indexPath.row]
            return optionCell(text: appearance.displayName,
                              checked: appearance == AppearanceManager.shared.current)

        case .textSize:
            let size = textSizes[indexPath.row]
            return optionCell(text: size.displayName,
                              checked: size == TextSizeManager.shared.current)

        case .language:
            let language = languages[indexPath.row]
            return optionCell(text: language.displayName,
                              checked: language == LocalizationManager.shared.currentLanguage)

        case .data:
            let row = DataRow(rawValue: indexPath.row) ?? .lastUpdate
            return valueCell(title: dataTitle(for: row), value: dataValue(for: row), selectable: false)

        case .about:
            let row = AboutRow(rawValue: indexPath.row) ?? .version
            switch row {
            case .version:
                return valueCell(title: L10n.Setting.aboutVersion, value: appVersionText(), selectable: false)
            case .source:
                return valueCell(title: L10n.Setting.aboutSource, value: "GitHub", selectable: true)
            }
        }
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch sections[section] {
        case .appearance: return L10n.Setting.sectionAppearance
        case .textSize: return L10n.Setting.sectionTextSize
        case .language: return L10n.Setting.sectionLanguage
        case .data: return L10n.Setting.sectionData
        case .about: return L10n.Setting.sectionAbout
        }
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        switch sections[section] {
        case .textSize: return L10n.Setting.sectionTextSizeFooter
        case .language: return L10n.Setting.sectionLanguageFooter
        case .about: return L10n.Setting.aboutIntro
        default: return nil
        }
    }
}

// MARK: - UITableViewDelegate

extension SettingVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)

        switch sections[indexPath.section] {
        case .appearance:
            selectAppearance(appearances[indexPath.row])
        case .textSize:
            selectTextSize(textSizes[indexPath.row])
        case .language:
            switchLanguage(to: languages[indexPath.row])
        case .data:
            break // 唯讀
        case .about:
            if AboutRow(rawValue: indexPath.row) == .source {
                openSourceCode()
            }
        }
    }
}
