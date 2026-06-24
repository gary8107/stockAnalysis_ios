//
//  AnalystSummary.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/24.
//

import Foundation

/// 分析師列表頁與個人頁共用的展示模型。
///
/// 設計取捨：把「分析師 key / 名稱 / 說明 / 圖片素材名稱」收斂成一個 UI 中性的型別，
/// 讓列表卡片與個人頁都不直接依賴後端 `Analyst` model，圖片素材的對應也只在這層轉一次。
struct AnalystSummary {
    let key: String
    let name: String
    let description: String
    /// 列表卡片用的橫幅圖片名稱（Assets.xcassets/Analyst）。
    let bannerImageName: String
    /// 個人頁頂部用的截圖圖片名稱（Assets.xcassets/screenshot）。
    let screenshotImageName: String

    /// 後備四位分析師：當注入的 `info.analysts` 尚未載入或缺漏時退回，確保列表不會空白。
    static let defaults: [AnalystSummary] = [
        AnalystSummary(key: "li-shufang", name: "李蜀芳", description: "",
                       bannerImageName: "lsf_banner", screenshotImageName: "lsf_screenshot"),
        AnalystSummary(key: "ruan-huici", name: "阮蕙慈", description: "",
                       bannerImageName: "rhc_banner", screenshotImageName: "rhc_screenshot"),
        AnalystSummary(key: "chen-kunjen", name: "陳昆仁(大仁哥)", description: "",
                       bannerImageName: "ckj_banner", screenshotImageName: "ckj_screenshot"),
        AnalystSummary(key: "cai-zhenghua", name: "蔡正華", description: "",
                       bannerImageName: "tzh_banner", screenshotImageName: "tzh_screenshot"),
    ]

    /// 從注入的 `Analyst` 清單建立展示模型；缺漏時退回預設四位。
    /// 圖片名稱沿用 `Analyst` 既有的 `banner` / `screenshot` 對應，維持單一來源。
    static func makeList(from analysts: [Analyst]?) -> [AnalystSummary] {
        let mapped = (analysts ?? []).compactMap { analyst -> AnalystSummary? in
            guard let key = analyst.key else { return nil }
            return AnalystSummary(key: key,
                                  name: analyst.name ?? "",
                                  description: analyst.description ?? "",
                                  bannerImageName: analyst.banner,
                                  screenshotImageName: analyst.screenshot)
        }
        return mapped.isEmpty ? defaults : mapped
    }
}
