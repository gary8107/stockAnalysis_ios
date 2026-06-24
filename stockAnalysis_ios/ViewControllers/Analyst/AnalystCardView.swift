//
//  AnalystCardView.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/24.
//

import UIKit
import SnapKit

/// 分析師列表頁的單張卡片：上方橫幅圖片，下方分析師名稱與說明，整張可點擊。
///
/// 設計取捨：
/// - **陰影 + 圓角分層**：陰影需要 `clipsToBounds = false`，圓角裁切需要 `clipsToBounds = true`，
///   兩者衝突，故外層 view 負責陰影、內層 `cardContentView` 負責圓角裁切。
/// - **只吃 `AnalystSummary`**：與後端 model 解耦，點擊事件用 closure 往外丟，導頁邏輯留在 VC。
final class AnalystCardView: UIView {

    /// 整張卡片被點擊時呼叫。
    var onTap: (() -> Void)?

    /// 橫幅圖片原始比例（高 / 寬）：素材為寬扁橫幅，沿用對照頁 Banner 的比例。
    private static let bannerAspectRatio: CGFloat = 450.0 / 2000.0

    /// 真正承載內容並做圓角裁切的容器（陰影由外層 self 畫，避免被裁掉）。
    private let cardContentView: UIView = {
        let view = UIView()
        view.backgroundColor = .secondarySystemGroupedBackground
        view.layer.cornerRadius = 12
        view.clipsToBounds = true
        return view
    }()

    private let bannerImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        return imageView
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 17, weight: .semibold)
        label.textColor = .label
        label.numberOfLines = 1
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14)
        label.textColor = .secondaryLabel
        label.numberOfLines = 2
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupLayout()
        setupShadow()
        setupTapGesture()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    /// 用展示模型填入卡片內容；說明為空時自動隱藏該行，避免留下空白。
    func configure(with summary: AnalystSummary) {
        bannerImageView.image = UIImage(named: summary.bannerImageName)
        nameLabel.text = summary.name
        descriptionLabel.text = summary.description
        descriptionLabel.isHidden = summary.description.isEmpty
    }

    private func setupLayout() {
        addSubview(cardContentView)
        cardContentView.addSubview(bannerImageView)
        cardContentView.addSubview(nameLabel)
        cardContentView.addSubview(descriptionLabel)

        cardContentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        bannerImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(bannerImageView.snp.width).multipliedBy(Self.bannerAspectRatio)
        }

        nameLabel.snp.makeConstraints { make in
            make.top.equalTo(bannerImageView.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview().inset(12)
        }

        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(nameLabel.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(12)
            make.bottom.equalToSuperview().inset(12)
        }
    }

    /// 卡片陰影：畫在外層 self.layer，所以 self 不能裁切（圓角交給內層 cardContentView）。
    private func setupShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.12
        layer.shadowRadius = 6
        layer.shadowOffset = CGSize(width: 0, height: 2)
    }

    private func setupTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(didTap))
        addGestureRecognizer(tapGesture)
    }

    @objc private func didTap() {
        onTap?()
    }
}
