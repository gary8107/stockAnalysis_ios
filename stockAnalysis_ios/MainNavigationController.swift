//
//  MainNavigationController.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/3.
//

import UIKit
import CYLTabBarController

/// 首頁的 Navigation 容器：外層包一個 UINavigationController，
/// 其 rootViewController 是放三個 Tab 的 CYLTabBarController（`MainViewController`）。
final class MainNavigationController: UINavigationController {

    /// 用「載入完成的資料」建立首頁。
    /// - Parameters:
    ///   - info: LoadingVC 取得的 API 資料，會往下注入給各個 Tab 使用。
    ///   - selectedTab: 建立後要預設停留的 Tab；預設 `nil` 表示維持第一個。
    ///     語系切換後重建首頁時，用它讓畫面停在使用者原本所在的 Tab（設定頁）。
    class func instantiate(info: StockAnalysisInfo? = nil,
                           selectedTab: TabBarType? = nil) -> UINavigationController {
        let tabBarController = MainViewController.instantiate(info: info, selectedTab: selectedTab)
        let navigationController = UINavigationController(rootViewController: tabBarController)
        return navigationController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        print("MainNavigationController")
    }
}

/// 首頁的 TabBar：包含 Comparison / Analyst / Setting 三個 Tab。
final class MainViewController: CYLTabBarController {

    /// 依 `TabBarManager` 定義的順序建立各 Tab，並把 `info` 注入給需要資料的 Tab。
    /// - Parameter selectedTab: 建立後預設停留的 Tab；`nil` 表示維持第一個。
    class func instantiate(info: StockAnalysisInfo? = nil,
                           selectedTab: TabBarType? = nil) -> MainViewController {
        let items = TabBarManager.items()
        // viewControllers 與 tabBarItemsAttributes 的順序必須一致，所以兩者都從同一份 items 衍生。
        let viewControllers = items.map { $0.makeViewController(info: info) }
        let tabBarItemsAttributes = TabBarManager.tabBarItemsAttributes()

        let tabBarController = MainViewController(viewControllers: viewControllers,
                                                  tabBarItemsAttributes: tabBarItemsAttributes)
        tabBarController.modalPresentationStyle = .fullScreen
        tabBarController.tabBar.barTintColor = .orange
        tabBarController.tabBar.tintColor = .red
        tabBarController.tabBar.unselectedItemTintColor = .darkGray

        // 重建首頁後讓畫面停在指定 Tab（例如語系切換是在設定頁觸發的，重建後要停回設定頁）。
        if let selectedTab, let index = items.firstIndex(of: selectedTab) {
            tabBarController.selectedIndex = index
        }
        return tabBarController
    }

    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

/// 集中管理 TabBar 的項目順序與每個項目的標題、圖示等屬性。
private enum TabBarManager {

    /// Tab 的顯示順序（左到右）。
    static func items() -> [TabBarType] {
        return [.comparison, .analyst, .setting]
    }

    /// CYLTabBarController 需要的屬性陣列，順序對應 `items()`。
    static func tabBarItemsAttributes() -> [[String: Any]] {
        return items().map { tabBarItemsAttribute(with: $0) }
    }

    private static func tabBarItemsAttribute(with type: TabBarType) -> [String: Any] {
        return [CYLTabBarItemTitle: type.title,
                CYLTabBarItemImage: type.iconNormal,
                CYLTabBarItemSelectedImage: type.iconSelected]
    }
}

/// 描述每個 Tab 的類型，以及它對應的標題、圖示與要建立的 ViewController。
enum TabBarType {
    case comparison
    case analyst
    case setting

    /// TabBar 顯示的標題，依目前語系即時取得本地化字串。
    var title: String {
        switch self {
        case .comparison: return L10n.Tab.comparison
        case .analyst: return L10n.Tab.analyst
        case .setting: return L10n.Tab.setting
        }
    }

    var iconNormal: UIImage {
        switch self {
        case .comparison: return UIImage(systemName: "arrow.left.arrow.right") ?? UIImage()
        case .analyst: return UIImage(systemName: "inset.filled.rectangle.and.person.filled") ?? UIImage()
        case .setting: return UIImage(systemName: "gearshape") ?? UIImage()
        }
    }

    var iconSelected: UIImage {
        switch self {
        case .comparison: return UIImage(systemName: "arrow.left.arrow.right") ?? UIImage()
        case .analyst: return UIImage(systemName: "inset.filled.rectangle.and.person.filled") ?? UIImage()
        case .setting: return UIImage(systemName: "gearshape") ?? UIImage()
        }
    }

    /// 建立此 Tab 對應的 ViewController，並把載入好的資料注入給需要的頁面。
    func makeViewController(info: StockAnalysisInfo?) -> UIViewController {
        switch self {
        case .comparison: return ComparisonVC.instantiate(info: info)
        case .analyst: return AnalystListVC.instantiate(info: info)
        case .setting: return SettingVC.instantiate(info: info)
        }
    }
}
