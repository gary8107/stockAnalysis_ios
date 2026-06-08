//
//  Comparison.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/3.
//

import UIKit
import FSPagerView
import SnapKit

/// 一筆要顯示在輪播 Banner 上的分析師資料。
/// 把「分析師 key」與「banner 圖片名稱」綁在一起，
/// 之後點擊 Banner 要導頁時可用 `analystKey` 找到對應的分析師。
private struct AnalystBanner {
    let analystKey: String?
    let imageName: String

    /// 後備用的四位分析師 banner。
    /// 當注入的 `info.analysts` 尚未載入或缺漏時退回這份，確保輪播一定有內容可顯示。
    static let defaults: [AnalystBanner] = [
        AnalystBanner(analystKey: "li-shufang", imageName: "lsf_banner"),
        AnalystBanner(analystKey: "ruan-huici", imageName: "rhc_banner"),
        AnalystBanner(analystKey: "chen-kunjen", imageName: "ckj_banner"),
        AnalystBanner(analystKey: "cai-zhenghua", imageName: "tzh_banner"),
    ]
}

/// 首頁（Comparison Tab）：頂部一個標題「分析師資料對照」，
/// 標題下方是四位分析師的輪播 Banner（自動輪播、無限循環、可點擊）。
class ComparisonVC: UIViewController {

    /// 由 LoadingVC 載入後注入的股票分析資料。
    private var info: StockAnalysisInfo?

    /// 輪播要顯示的 banner 清單。
    /// 優先採用注入資料中的分析師（用各自的 `banner` 圖片），缺漏時退回預設四位。
    private lazy var banners: [AnalystBanner] = makeBanners()

    private static let bannerCellIdentifier = "AnalystBannerCell"

    /// banner 圖片的原始比例（高 / 寬，實際素材為 2276×377 的寬扁橫幅）。
    /// 用它讓輪播容器的高度隨寬度等比縮放，圖片才不會被裁切或變形。
    private static let bannerAspectRatio: CGFloat = 450.0 / 2000.0

    /// 輪播 Banner 本體（FSPagerView）。
    private lazy var pagerView: FSPagerView = {
        let pager = FSPagerView()
        pager.dataSource = self
        pager.delegate = self
        pager.register(FSPagerViewCell.self, forCellWithReuseIdentifier: Self.bannerCellIdentifier)
        // itemSize 用 automaticSize 讓每張 banner 填滿整個 pager 寬度（單張全幅輪播）。
        pager.itemSize = FSPagerView.automaticSize
        pager.isInfinite = true              // 無限循環，滑到最後一張可接回第一張。
        pager.automaticSlidingInterval = 3.0 // 每 3 秒自動切下一張。
        return pager
    }()

    /// 輪播下方的頁數指示點。
    private lazy var pageControl: FSPageControl = {
        let control = FSPageControl()
        control.contentHorizontalAlignment = .center
        control.setFillColor(.systemRed, for: .selected)
        control.setFillColor(.lightGray, for: .normal)
        return control
    }()

    class func instantiate(info: StockAnalysisInfo? = nil) -> ComparisonVC {

        let viewController = ComparisonVC()
        viewController.info = info
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        setupLayout()
        pageControl.numberOfPages = banners.count
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        // 本頁是 TabBar 子頁，外層 NavigationBar 屬於 TabBarController。
        // 在這裡設定 TabBarController 的 navigationItem.title 才會顯示在 NavigationBar，
        // 且不會像設 self.title 那樣污染底部 Tab 文字。每次切回本頁都會重設，確保標題正確。
        tabBarController?.navigationItem.title = L10n.Comparison.title
    }

    /// 用 SnapKit 排版：頂部為輪播 Banner，其下接頁數指示點。
    /// 頁面標題「分析師資料對照」改由外層 NavigationBar 呈現（見 MainViewController），此處不再放標題 Label。
    private func setupLayout() {
        view.addSubview(pagerView)
        view.addSubview(pageControl)

        pagerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            // 高度依 banner 原始比例隨寬度等比縮放，避免裁切或變形。
            make.height.equalTo(pagerView.snp.width).multipliedBy(Self.bannerAspectRatio)
        }

        pageControl.snp.makeConstraints { make in
            make.top.equalTo(pagerView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(20)
        }
    }

    /// 從注入資料建立 banner 清單；缺漏時退回預設四位，確保輪播不會空白。
    private func makeBanners() -> [AnalystBanner] {
        let fromData = (info?.analysts ?? []).compactMap { analyst -> AnalystBanner? in
            // Analyst.banner 會把分析師 key 對應到 banner 圖片名稱；對不到時回傳空字串，這裡濾掉。
            let imageName = analyst.banner
            guard !imageName.isEmpty else { return nil }
            return AnalystBanner(analystKey: analyst.key, imageName: imageName)
        }
        return fromData.isEmpty ? AnalystBanner.defaults : fromData
    }
}

// MARK: - FSPagerViewDataSource

extension ComparisonVC: FSPagerViewDataSource {

    func numberOfItems(in pagerView: FSPagerView) -> Int {
        banners.count
    }

    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        let cell = pagerView.dequeueReusableCell(withReuseIdentifier: Self.bannerCellIdentifier, at: index)
        let banner = banners[index]

        cell.imageView?.image = UIImage(named: banner.imageName)
        cell.imageView?.contentMode = .scaleAspectFill
        cell.imageView?.clipsToBounds = true
        cell.imageView?.layer.cornerRadius = 12
        // 注意：刻意不存取 cell.textLabel。
        // 它的 getter 第一次被讀取就會建立一塊半透明黑底（用來襯托文字）並蓋在圖片下半部，
        // 我們的 banner 不需要文字，碰它反而會冒出那塊黑色遮罩，所以完全不要動它。
        return cell
    }
}

// MARK: - FSPagerViewDelegate

extension ComparisonVC: FSPagerViewDelegate {

    /// 滑動時同步更新頁數指示點。
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        pageControl.currentPage = pagerView.currentIndex
    }

    /// 點擊 Banner。實際導頁 / 詳情功能之後再做，這裡先保留點擊行為與對應的分析師資訊。
    func pagerView(_ pagerView: FSPagerView, didSelectItemAt index: Int) {
        pagerView.deselectItem(at: index, animated: true)
        let banner = banners[index]
        // TODO: 之後接上分析師詳情頁，可用 banner.analystKey 取得對應分析師。
        print("tapped analyst banner: \(banner.analystKey ?? "unknown")")
    }
}
