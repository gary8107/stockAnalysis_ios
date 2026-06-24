//
//  AnalystDetailVC.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/24.
//

import UIKit
import SnapKit

/// 分析師個人頁：由列表頁點卡片進入，只服務「單一」分析師。
///
/// 版面（sticky header 捲動）：
/// - 整頁是一個 ScrollView，由上到下放：該分析師的 screenshot（單張固定，不輪播）→ 內容區。
/// - 「月份/日期選擇器」以浮層方式疊在最上層：往下捲動時 screenshot 會跟著往上捲走，
///   但選擇器捲到頂端後就「釘」在最上方不再上移，藉此讓下方內容有更大的閱讀範圍。
///
/// 實作要點：選擇器不是放在 ScrollView 內，而是疊在 `view` 上，
/// 由 `scrollViewDidScroll` 依捲動量動態調整它距頂端的位移：
///   位移 = max(0, screenshot 底部在畫面上的 y - 捲動量)，到 0 即釘住。
/// ScrollView 內以一個等高的 placeholder 佔住選擇器原本的位置，避免內容被選擇器蓋住。
class AnalystDetailVC: UIViewController, UIScrollViewDelegate {

    /// 本頁服務的分析師（含名稱與 screenshot 圖片名稱）。
    private var summary: AnalystSummary!

    /// 由 LoadingVC 載入後注入、再經列表頁傳入的股票分析資料。
    private var info: StockAnalysisInfo?

    /// 本分析師「日期字串（yyyy-MM-dd）→ note」查表，方便選到日期後快速取回對應 note。
    private lazy var notesByDate: [String: AnalystNote] = makeNotesByDate()

    /// screenshot 原始比例（高 / 寬）：素材為 1280×720 的 16:9 橫圖，依此等比縮放避免裁切變形。
    private static let screenshotAspectRatio: CGFloat = 720.0 / 1280.0

    /// screenshot 與下方選擇器之間的間距，也是選擇器「自然位置」的計算基準。
    private static let screenshotBottomSpacing: CGFloat = 16

    /// sticky header 容器（含選擇器）的固定高度。
    /// MonthDatePickerView 內部高度固定（月份鈕 32 + 間距 12 + 日期列 36 = 80），上下各留 8 內距 → 96。
    /// 若日後選擇器內部高度調整，這個常數要一起更新。
    private static let stickyHeaderHeight: CGFloat = 96

    // MARK: - 子視圖

    /// 整頁捲動容器。
    private let pageScrollView: UIScrollView = {
        let scroll = UIScrollView()
        scroll.alwaysBounceVertical = true
        // 已手動把 top 釘在 safeArea，關閉自動 inset 調整以免和 NavigationBar 重複內縮。
        scroll.contentInsetAdjustmentBehavior = .never
        return scroll
    }()

    /// ScrollView 的內容容器。
    private let contentView = UIView()

    /// 頂部該分析師的 screenshot（單張，不切換）。
    private let screenshotImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 12
        return imageView
    }()

    /// 佔位視圖：在 ScrollView 內佔住選擇器原本的高度，讓內容不會被浮層選擇器蓋住。
    private let headerPlaceholderView = UIView()

    /// 內容區（不捲動，跟著外層 ScrollView 一起捲）。
    private let contentBlocksView = ContentBlocksStackView()

    /// sticky header 容器：疊在 view 最上層，承載選擇器並提供不透明底色，
    /// 釘住時可遮住從下方捲上來的內容。
    private let stickyHeaderView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        return view
    }()

    /// 釘住時用來和內容做出區隔的底部細線（捲到頂端釘住時才顯示）。
    private let stickyHeaderSeparator: UIView = {
        let view = UIView()
        view.backgroundColor = .separator
        view.alpha = 0
        return view
    }()

    /// 內容建構中的讀取遮罩（可重用元件，見 Components/Loading）。
    /// 內容首次渲染延到轉場後才做（見 hasAppeared），切換日期也是重建構，這段期間用它覆蓋畫面、讓使用者知道正在讀取。
    private let loadingOverlay = LoadingOverlayView()

    /// 「月份下拉 + 日期膠囊」選擇器（可重用元件，見 Components/MonthDatePicker）。
    private lazy var monthDatePicker: MonthDatePickerView = {
        let picker = MonthDatePickerView()
        picker.onSelectDate = { [weak self] date in
            self?.didSelectDate(date)
        }
        return picker
    }()

    /// sticky header 距 safeArea 頂端的位移約束（隨捲動更新）。
    private var stickyHeaderTopConstraint: Constraint?

    /// 目前選取的日期（由選擇器回呼更新）。轉場結束後用它做初次渲染。
    private var selectedDate: Date?

    /// 是否已完成進場轉場。
    /// 用途：內容（含多格表格、attributed string、大量 Auto Layout 約束）建構成本不低，
    /// 若在 viewDidLoad 同步做，會卡在「點擊 → push 動畫開始」之間，造成點擊反應遲鈍。
    /// 因此把「初次內容渲染」延到轉場結束（viewDidAppear）後，讓進場瞬間滑入、內容隨後補上；
    /// 之後在頁內點日期切換時人已在頁面上，照常即時渲染。
    private var hasAppeared = false

    class func instantiate(summary: AnalystSummary, info: StockAnalysisInfo? = nil) -> AnalystDetailVC {

        let viewController = AnalystDetailVC()
        viewController.summary = summary
        viewController.info = info
        return viewController
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        view.backgroundColor = .systemBackground
        // 本頁是被 push 進來的（非 TabBar 子頁），可直接用 self.title 顯示在 NavigationBar，
        // 不會有 CYLTabBarController 子頁設 self.title 會污染底部 Tab 文字的問題。
        title = summary.name

        screenshotImageView.image = UIImage(named: summary.screenshotImageName)
        pageScrollView.delegate = self
        setupLayout()

        // 把本分析師的 note 日期餵給選擇器；元件內部自行分組、排序、產生月份選單與日期列，
        // 並預設選取最新月份與最新一天、回呼 onSelectDate 連帶刷新內容。
        monthDatePicker.setDates(noteDates())
        applyPickerEmptyStateIfNeeded()

        // 有日期待渲染（非空狀態）時先顯示讀取遮罩，等轉場後 viewDidAppear 才真正建構內容。
        if selectedDate != nil {
            loadingOverlay.show(in: view, text: L10n.Common.loading)
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        // 轉場已結束，才做初次內容渲染（見 hasAppeared 說明），避免拖慢進場手感。
        guard !hasAppeared else { return }
        hasAppeared = true
        guard let date = selectedDate else { return }

        // 再 async 一拍，讓讀取轉圈先畫出來，避免緊接著的同步重建構把這一幀吃掉、轉圈看不到。
        DispatchQueue.main.async { [weak self] in
            self?.renderContent(for: date)
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        // 版面確定（screenshot 高度已知）後，更新選擇器初始位置。
        updateStickyHeaderPosition()
    }

    /// 用 SnapKit 排版：ScrollView 內為 screenshot + placeholder + 內容；選擇器另疊在最上層。
    private func setupLayout() {
        view.addSubview(pageScrollView)
        pageScrollView.addSubview(contentView)
        contentView.addSubview(screenshotImageView)
        contentView.addSubview(headerPlaceholderView)
        contentView.addSubview(contentBlocksView)

        // 選擇器浮層疊在 ScrollView 之上（最後加入確保在最上層）。
        view.addSubview(stickyHeaderView)
        stickyHeaderView.addSubview(monthDatePicker)
        stickyHeaderView.addSubview(stickyHeaderSeparator)

        pageScrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top)
            make.leading.trailing.bottom.equalToSuperview()
        }

        contentView.snp.makeConstraints { make in
            make.edges.equalTo(pageScrollView.contentLayoutGuide)
            // 內容寬度 = 捲動視窗寬度 → 只垂直捲動，不橫向。
            make.width.equalTo(pageScrollView.frameLayoutGuide)
        }

        screenshotImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            // 高度依 screenshot 原始比例隨寬度等比縮放，避免裁切或變形。
            make.height.equalTo(screenshotImageView.snp.width).multipliedBy(Self.screenshotAspectRatio)
        }

        // placeholder 佔住選擇器原本的位置（緊接 screenshot 下方），高度等於 sticky header。
        headerPlaceholderView.snp.makeConstraints { make in
            make.top.equalTo(screenshotImageView.snp.bottom).offset(Self.screenshotBottomSpacing)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Self.stickyHeaderHeight)
        }

        contentBlocksView.snp.makeConstraints { make in
            make.top.equalTo(headerPlaceholderView.snp.bottom).offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().inset(24)
        }

        // sticky header：左右滿版（釘住時兩側也能遮住內容），高度固定，top 由捲動動態調整。
        stickyHeaderView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(Self.stickyHeaderHeight)
            stickyHeaderTopConstraint = make.top.equalTo(view.safeAreaLayoutGuide.snp.top).constraint
        }

        monthDatePicker.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.bottom.equalToSuperview().offset(-8)
        }

        stickyHeaderSeparator.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(1.0 / UIScreen.main.scale)
        }
    }

    // MARK: - Sticky header 位置

    /// 依捲動量更新選擇器距頂端的位移：到頂端即釘住，並淡入底部分隔線。
    private func updateStickyHeaderPosition() {
        // screenshot 底部下方 spacing 即選擇器的「自然位置」（內容座標 = 畫面座標，因 ScrollView top 對齊 safeArea）。
        let naturalTop = screenshotImageView.frame.maxY + Self.screenshotBottomSpacing
        let offset = max(0, naturalTop - pageScrollView.contentOffset.y)
        stickyHeaderTopConstraint?.update(offset: offset)

        // 已釘到頂端（offset 收斂到 0）時顯示分隔線，提示內容正從下方捲過。
        stickyHeaderSeparator.alpha = offset <= 0.5 ? 1 : 0
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateStickyHeaderPosition()
    }

    /// 沒有任何 note 時，選擇器不會回呼，這裡主動把選擇器與佔位收起、內容區清成空狀態。
    private func applyPickerEmptyStateIfNeeded() {
        guard monthDatePicker.isEmpty else { return }
        stickyHeaderView.isHidden = true
        // 收掉佔位高度，讓內容直接接在 screenshot 下方。
        headerPlaceholderView.snp.updateConstraints { make in
            make.height.equalTo(0)
        }
        contentBlocksView.setBlocks([], emptyText: L10n.Analyst.contentEmpty)
    }

    // MARK: - 月份 / 日期

    /// 解析 note 的 date 字串用的格式器（固定 yyyy-MM-dd、POSIX locale，確保解析穩定）。
    private static let isoDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter
    }()

    /// 本分析師所有可解析的 note 日期清單，餵給選擇器。
    /// 分組、排序、月份標題等都交給 `MonthDatePickerView`，本頁只負責把業務資料轉成 `[Date]`。
    private func noteDates() -> [Date] {
        notesByDate.keys.compactMap { Self.isoDateFormatter.date(from: $0) }
    }

    /// 選擇器回呼：記住日期。
    /// - 轉場結束前（hasAppeared == false）只記錄不渲染，初次渲染交給 viewDidAppear，避免卡住進場動畫。
    /// - 轉場後（使用者在頁內點日期）：先顯示讀取轉圈再建構，讓點擊立即有回饋、不會像沒反應。
    private func didSelectDate(_ date: Date) {
        selectedDate = date
        guard hasAppeared else { return }
        showLoadingThenRender(for: date)
    }

    /// 先把讀取轉圈顯示出來，下一拍 runloop 再做（成本較高的）內容建構。
    /// 多等一拍是為了讓轉圈先畫出一幀，否則緊接著的同步重建構會吃掉那一幀，使用者看不到讀取回饋。
    private func showLoadingThenRender(for date: Date) {
        loadingOverlay.show(in: view, text: L10n.Common.loading)
        DispatchQueue.main.async { [weak self] in
            self?.renderContent(for: date)
        }
    }

    /// 真正把某日期的內容建出來並交給內容區渲染。
    private func renderContent(for date: Date) {
        let dateString = Self.isoDateFormatter.string(from: date)
        let blocks = notesByDate[dateString].map(contentBlocks(from:)) ?? []
        contentBlocksView.setBlocks(blocks, emptyText: L10n.Analyst.contentEmpty)

        // 內容已就緒，收起讀取遮罩。
        loadingOverlay.hide()

        // 換內容後高度改變，捲回頂端並重算選擇器位置。
        pageScrollView.setContentOffset(.zero, animated: false)
        updateStickyHeaderPosition()
    }

    /// 建立本分析師的「日期字串 → note」查表。
    /// 只收 `analyst_key` 等於本分析師的 note；同一天若有多筆，保留第一筆即可（資料目前每天唯一）。
    private func makeNotesByDate() -> [String: AnalystNote] {
        var result: [String: AnalystNote] = [:]
        for note in info?.notes ?? [] {
            guard note.analystKey == summary.key,
                  let dateString = note.date,
                  result[dateString] == nil else { continue }
            result[dateString] = note
        }
        return result
    }

    /// 把 web service 的 `[Block]` 對應成 UI 中性的 `[ContentBlock]`。
    /// 這層 mapping 刻意留在 VC，讓 ContentBlocks 元件完全不依賴後端 model。
    private func contentBlocks(from note: AnalystNote) -> [ContentBlock] {
        (note.blocks ?? []).compactMap { block -> ContentBlock? in
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
