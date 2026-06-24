//
//  AppRootBuilder.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/8.
//

import UIKit

extension UIApplication {
    /// 取得目前作用中的 key window。
    ///
    /// 本專案為 Scene-based 架構，window 由各個 `UIWindowScene` 持有，
    /// 因此走 `connectedScenes` 找出前景中的場景再取其 key window，
    /// 不使用已被棄用的 `UIApplication.shared.keyWindow`。
    var activeKeyWindow: UIWindow? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first { $0.activationState == .foregroundActive }?
            .windows
            .first { $0.isKeyWindow }
    }
}

/// 負責建立與切換 App 的 root 畫面。
///
/// 抽出來的原因：「重建首頁」這件事會被多處用到
/// （載入完成後第一次進首頁、語系切換後重建首頁刷新 TabBar 標題），
/// 集中在一處可避免邏輯重複，也方便日後改變切換時的轉場效果。
enum AppRootBuilder {

    /// 用載入好的資料建立首頁（三個 Tab 的容器）。
    /// - Parameters:
    ///   - info: 由 `LoadingVC` 取得、要往下注入各 Tab 的股票分析資料。
    ///   - selectedTab: 重建後要預設停留的 Tab；預設 `nil` 表示維持原本順序的第一個。
    static func makeHome(info: StockAnalysisInfo?, selectedTab: TabBarType? = nil) -> UIViewController {
        MainNavigationController.instantiate(info: info, selectedTab: selectedTab)
    }

    /// 把指定 window 的 root 換成新的畫面，並加上淡入轉場避免硬切。
    /// - Parameters:
    ///   - viewController: 新的 root view controller。
    ///   - window: 目標 window；預設取目前作用中的 key window。
    static func switchRoot(to viewController: UIViewController, in window: UIWindow? = nil) {
        guard let targetWindow = window ?? UIApplication.shared.activeKeyWindow else { return }

        targetWindow.rootViewController = viewController
        // 重建 root 後重新套用外觀模式，確保新畫面沿用使用者選擇（override 是 window 屬性，通常會留著，這裡保險再套一次）。
        AppearanceManager.shared.apply(to: targetWindow)
        UIView.transition(with: targetWindow,
                          duration: 0.3,
                          options: .transitionCrossDissolve,
                          animations: nil,
                          completion: nil)
    }
}
