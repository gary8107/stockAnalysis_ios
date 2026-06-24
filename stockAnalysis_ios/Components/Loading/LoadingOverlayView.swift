//
//  LoadingOverlayView.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/24.
//

import UIKit
import SnapKit

/// 全螢幕讀取遮罩：半透明灰底 + 置中的深色 HUD 卡片（轉圈 + 文字）。
///
/// 設計取捨（為什麼這樣做）：
/// - **可重用、不綁特定頁面**：呼叫 `show(in:text:)` 把自己疊到任一 host view、`hide()` 收掉，
///   對照頁、分析師頁…都能共用同一個讀取視覺。
/// - **整片變灰 + 深色 HUD**：單純一顆轉圈在淺色內容上不夠明顯；用半透明灰底壓暗整個畫面、
///   再放一張深色圓角卡片承載白色轉圈與文字，讀取狀態一眼可辨，也順帶擋住點擊（避免讀取中重複觸發）。
/// - **淡入淡出**：避免內容很快就緒時硬切造成閃爍感。
final class LoadingOverlayView: UIView {

    /// 淡入 / 淡出時間。
    private static let fadeDuration: TimeInterval = 0.15

    private let hudView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.75)
        view.layer.cornerRadius = 12
        return view
    }()

    private let indicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .white
        // 由本元件的 show/hide 控制顯示，停止時也保留在卡片上，不自動藏。
        indicator.hidesWhenStopped = false
        return indicator
    }()

    private let label: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = .systemFont(ofSize: 14)
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    init() {
        super.init(frame: .zero)
        // 半透明灰底：壓暗整個畫面，並吃掉底下的點擊（讀取中不應再互動）。
        backgroundColor = UIColor.black.withAlphaComponent(0.35)
        isHidden = true
        setupLayout()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayout() {
        let stack = UIStackView(arrangedSubviews: [indicator, label])
        stack.axis = .vertical
        stack.alignment = .center
        stack.spacing = 12

        addSubview(hudView)
        hudView.addSubview(stack)

        hudView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.greaterThanOrEqualTo(120)
        }
        stack.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(UIEdgeInsets(top: 20, left: 24, bottom: 20, right: 24))
        }
    }

    // MARK: - 對外 API

    /// 把遮罩疊到 `host` 上並淡入。重複呼叫只會更新文字並確保在最上層。
    /// - Parameters:
    ///   - host: 要覆蓋的容器視圖（通常是 VC 的 view）。
    ///   - text: HUD 顯示的文字（如「讀取中…」）。
    func show(in host: UIView, text: String) {
        label.text = text

        if superview !== host {
            removeFromSuperview()
            host.addSubview(self)
            snp.remakeConstraints { make in
                make.edges.equalToSuperview()
            }
        }
        host.bringSubviewToFront(self)

        indicator.startAnimating()
        isHidden = false
        // 已經顯示中就不重播淡入動畫，避免閃爍。
        guard alpha < 1 else { return }
        alpha = 0
        UIView.animate(withDuration: Self.fadeDuration) { self.alpha = 1 }
    }

    /// 淡出並從畫面移除。
    func hide() {
        guard superview != nil, !isHidden else { return }
        UIView.animate(withDuration: Self.fadeDuration, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.indicator.stopAnimating()
            self.isHidden = true
            self.removeFromSuperview()
        })
    }
}
