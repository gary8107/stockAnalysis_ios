//
//  SettingVC.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/3.
//

import UIKit

/// 設定頁。目前提供「語言切換」功能：
/// 以一個分組表格列出 App 支援的所有語系，勾選目前使用中的語系，
/// 點選其他語系即時切換並重建首頁，讓整個 App（含 TabBar 標題）立刻換成新語言。
final class SettingVC: UIViewController {

    /// 由 LoadingVC 載入後一路注入到此的股票分析資料。
    /// 切換語系需要重建首頁，重建時要把同一份資料再傳下去，避免資料遺失，所以這裡要持有。
    private var info: StockAnalysisInfo?

    /// 畫面要呈現的所有語系選項。固定取自 `AppLanguage.allCases`，
    /// 之後新增語言時這份清單會自動跟著更新。
    private let languages = AppLanguage.allCases

    private lazy var tableView: UITableView = {
        // 用 .insetGrouped 取得 iOS 設定 App 那種分組外觀，並能顯示 section 的標題與說明文字。
        let tableView = UITableView(frame: .zero, style: .insetGrouped)
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: Self.cellIdentifier)
        return tableView
    }()

    private static let cellIdentifier = "LanguageCell"

    class func instantiate(info: StockAnalysisInfo? = nil) -> SettingVC {
        let viewController = SettingVC()
        viewController.info = info
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemGroupedBackground
        setupTableView()
        applyLocalizedTexts()
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

    /// 套用（或重新套用）目前語系的本地化文字。
    /// 抽成獨立方法，讓「進入畫面」與「語系切換後刷新」共用同一段邏輯。
    private func applyLocalizedTexts() {
        tableView.reloadData()
    }

    /// 切換到指定語系。
    /// - 相同語系不做事（避免無謂重建）。
    /// - 透過 `LocalizationManager` 更新語系（會持久化並發出通知），
    ///   再重建首頁讓 TabBar 標題等全畫面即時換成新語言，並停回設定頁。
    private func switchLanguage(to language: AppLanguage) {
        guard language != LocalizationManager.shared.currentLanguage else { return }

        LocalizationManager.shared.setLanguage(language)

        let home = AppRootBuilder.makeHome(info: info, selectedTab: .setting)
        AppRootBuilder.switchRoot(to: home, in: view.window)
    }
}

// MARK: - UITableViewDataSource

extension SettingVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        languages.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: Self.cellIdentifier, for: indexPath)
        let language = languages[indexPath.row]

        // 部署目標為 iOS 13，沿用傳統的 textLabel API（defaultContentConfiguration 需 iOS 14+）。
        cell.textLabel?.text = language.displayName

        // 目前使用中的語系打勾，讓使用者一眼看出現在的選擇。
        cell.accessoryType = (language == LocalizationManager.shared.currentLanguage) ? .checkmark : .none
        return cell
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        L10n.Setting.sectionLanguage
    }

    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        L10n.Setting.sectionLanguageFooter
    }
}

// MARK: - UITableViewDelegate

extension SettingVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switchLanguage(to: languages[indexPath.row])
    }
}
