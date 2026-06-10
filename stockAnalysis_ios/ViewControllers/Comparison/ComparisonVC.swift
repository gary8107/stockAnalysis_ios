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

    /// Banner 下方的「月份下拉 + 日期膠囊」選擇器（可重用元件，見 Components/MonthDatePicker）。
    private lazy var monthDatePicker: MonthDatePickerView = {
        let picker = MonthDatePickerView()
        picker.onSelectDate = { [weak self] date in
            self?.didSelectDate(date)
        }
        return picker
    }()

    /// 選擇器下方的內容區：顯示選定日期該筆 comparison 的 blocks（可重用元件，見 Components/ContentBlocks）。
    private let contentBlocksView = ContentBlocksView()

    /// 以日期字串（yyyy-MM-dd）為 key 的 comparison 查表，方便選到日期後快速取回對應資料。
    private lazy var comparisonsByDate: [String: AnalystComparison] = makeComparisonsByDate()

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

        // 把 comparisons 解析成日期餵給選擇器；元件內部自行分組、排序、產生月份選單與日期列。
        monthDatePicker.setDates(comparisonDates())
        monthDatePicker.isHidden = monthDatePicker.isEmpty
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
        view.addSubview(monthDatePicker)
        view.addSubview(contentBlocksView)

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

        // 月份 + 日期選擇器：高度由元件內部約束自我撐起，這裡只釘上緣與左右。
        monthDatePicker.snp.makeConstraints { make in
            make.top.equalTo(pageControl.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
        }

        // 內容區：填滿選擇器以下到頁面底部，內部自行垂直捲動（Banner 與選擇器固定在上方）。
        contentBlocksView.snp.makeConstraints { make in
            make.top.equalTo(monthDatePicker.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom)
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

    // MARK: - 月份 / 日期

    /// 解析 comparisons 的 date 字串用的格式器（固定 yyyy-MM-dd、POSIX locale，確保解析穩定）。
    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// 把注入資料的 comparisons 取出可解析的日期清單，餵給選擇器。
    /// 分組、排序、月份標題等都交給 `MonthDatePickerView`，本頁只負責把業務資料轉成 `[Date]`。
    private func comparisonDates() -> [Date] {
        (info?.comparisons ?? []).compactMap { comparison in
            guard let dateString = comparison.date else { return nil }
            return Self.isoDateFormatter.date(from: dateString)
        }
    }

    /// 選到某個日期：取回該日 comparison，轉成中性的 ContentBlock 後交給內容區渲染。
    /// 初次載入、換月、使用者點日期三種情況都會走到這裡（見 DatePillTabBar 對預設選取也通知）。
    private func didSelectDate(_ date: Date) {
        let dateString = Self.isoDateFormatter.string(from: date)
        let blocks = comparisonsByDate[dateString].map(contentBlocks(from:)) ?? []
        contentBlocksView.setBlocks(blocks, emptyText: L10n.Comparison.empty)
    }

    /// 建立「日期字串 → comparison」查表。同一天若有多筆，保留第一筆即可（資料目前每天唯一）。
    private func makeComparisonsByDate() -> [String: AnalystComparison] {
        var result: [String: AnalystComparison] = [:]
        for comparison in info?.comparisons ?? [] {
            guard let dateString = comparison.date, result[dateString] == nil else { continue }
            result[dateString] = comparison
        }
        return result
    }

    /// 把 web service 的 `[Block]` 對應成 UI 中性的 `[ContentBlock]`。
    /// 這層 mapping 刻意留在 VC，讓 ContentBlocks 元件完全不依賴後端 model。
    private func contentBlocks(from comparison: AnalystComparison) -> [ContentBlock] {
        (comparison.blocks ?? []).compactMap { block -> ContentBlock? in
            switch block.type {
            case .markdown:
                guard let content = block.content, !content.isEmpty else { return nil }
                return .markdown(content)
            case .table:
                return .table(headers: block.headers ?? [], rows: block.rows ?? [])
            case .none:
                return nil
            }
        }
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

        // FSPagerViewCell 預設會在 contentView.layer 畫一層黑色陰影（shadowOpacity 0.75）。
        // 該陰影依 cell 的「方形 bounds」繪製，不會跟著上面 imageView 的圓角縮，
        // 因此會從圓角外露出，形成四個角落的陰影。這裡關掉陰影即可消除。
        cell.contentView.layer.shadowOpacity = 0
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
