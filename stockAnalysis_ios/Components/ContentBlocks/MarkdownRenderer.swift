//
//  MarkdownRenderer.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/10.
//

import UIKit

/// 輕量的 markdown → NSAttributedString 轉換器。
///
/// 為什麼自己寫而不引入套件：
/// - 部署目標 iOS 13 無法用 `AttributedString(markdown:)`（iOS 15+）；
/// - 本專案內容以 **粗體**、emoji、標題、清單、行內連結為主，需求單純，
///   自寫一個小 parser 即可，零相依、好控制、好測試。
///
/// 支援語法（刻意只做需要的子集）：
/// - 標題：行首 `#`～`######`（井號數量決定字級）。
/// - 清單：行首（可含縮排空白）`- ` 或 `* ` → 轉成「• 」並依縮排內縮。
/// - 行內粗體：`**文字**`。
/// - 行內斜體：`*文字*`。
/// - 連結：`[顯示文字](網址)` → 只保留「顯示文字」（本專案連結指向內部 .md，不是真網址）。
enum MarkdownRenderer {

    /// 各標題層級對應的基準字級（index 0 不用，1 = `#` 最大、6 最小）。
    private static let baseHeadingFontSizes: [CGFloat] = [0, 24, 21, 18, 16, 15, 14]

    /// 內文與清單的基準字級。
    private static let baseBodyFontSize: CGFloat = 15

    /// 套用使用者字體大小倍率後的標題字級。
    /// 倍率在「每次渲染當下」讀取，因此字級切換後重建畫面即可生效（見 TextSizeManager）。
    private static func headingFontSize(level: Int) -> CGFloat {
        baseHeadingFontSizes[level] * TextSizeManager.shared.scale
    }

    /// 套用使用者字體大小倍率後的內文字級。
    private static var bodyFontSize: CGFloat {
        baseBodyFontSize * TextSizeManager.shared.scale
    }

    /// 把一整段 markdown 文字轉成可直接丟給 UILabel 的 NSAttributedString。
    /// - Parameters:
    ///   - markdown: 來源文字（可含多行）。
    ///   - textColor: 文字顏色，預設 `.label`。
    static func attributedString(from markdown: String, textColor: UIColor = .label) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let lines = markdown.components(separatedBy: "\n")

        for (index, rawLine) in lines.enumerated() {
            let lineAttributed = attributedLine(for: rawLine, textColor: textColor)
            result.append(lineAttributed)
            // 行與行之間補換行（最後一行不補，避免尾端多一個空行）。
            if index < lines.count - 1 {
                result.append(NSAttributedString(string: "\n"))
            }
        }
        return result
    }

    /// 只做「行內」格式（粗體 / 斜體 / 連結）的轉換，不處理標題與清單。
    /// 表格儲存格會用到（格子內也有 `**粗體**`），所以單獨開放。
    static func inlineAttributedString(from text: String,
                                       font: UIFont,
                                       textColor: UIColor = .label) -> NSAttributedString {
        applyInlineStyles(to: stripLinks(in: text), baseFont: font, textColor: textColor)
    }

    // MARK: - 單行處理

    /// 處理單行：先判斷是否為標題或清單，再套行內格式。
    private static func attributedLine(for rawLine: String, textColor: UIColor) -> NSAttributedString {
        // 標題：行首連續井號 + 空白。
        if let heading = parseHeading(rawLine) {
            let font = UIFont.systemFont(ofSize: headingFontSize(level: heading.level), weight: .bold)
            return inlineAttributedString(from: heading.text, font: font, textColor: textColor)
        }

        // 清單：行首（允許縮排）`- ` 或 `* `。
        if let listItem = parseListItem(rawLine) {
            let indent = String(repeating: "  ", count: listItem.indentLevel)
            let bulletLine = "\(indent)• \(listItem.text)"
            // bullet 前綴用一般內文字級即可；行內格式套在整行（含 bullet 不影響）。
            let font = UIFont.systemFont(ofSize: bodyFontSize)
            return inlineAttributedString(from: bulletLine, font: font, textColor: textColor)
        }

        // 一般內文。
        let font = UIFont.systemFont(ofSize: bodyFontSize)
        return inlineAttributedString(from: rawLine, font: font, textColor: textColor)
    }

    /// 解析標題行，回傳層級（1~6）與去掉井號後的文字；不是標題回傳 nil。
    private static func parseHeading(_ line: String) -> (level: Int, text: String)? {
        var level = 0
        let characters = Array(line)
        while level < characters.count && characters[level] == "#" {
            level += 1
        }
        // 必須是 1~6 個井號、且後面接一個空白才算標題。
        guard level >= 1, level <= 6, level < characters.count, characters[level] == " " else {
            return nil
        }
        let text = String(characters[(level + 1)...]).trimmingCharacters(in: .whitespaces)
        return (level, text)
    }

    /// 解析清單項目，回傳縮排層級與項目文字；不是清單回傳 nil。
    private static func parseListItem(_ line: String) -> (indentLevel: Int, text: String)? {
        // 算行首空白數，每 2 個空白視為一層縮排。
        let leadingSpaces = line.prefix { $0 == " " }.count
        let trimmed = line.drop { $0 == " " }
        guard trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") else { return nil }
        let text = String(trimmed.dropFirst(2))
        return (leadingSpaces / 2, text)
    }

    // MARK: - 行內格式

    /// 把 `[文字](網址)` 取代成只剩「文字」。
    private static func stripLinks(in text: String) -> String {
        guard let regex = try? NSRegularExpression(pattern: "\\[([^\\]]+)\\]\\([^)]*\\)") else {
            return text
        }
        let range = NSRange(text.startIndex..., in: text)
        return regex.stringByReplacingMatches(in: text, range: range, withTemplate: "$1")
    }

    /// 套用行內粗體 / 斜體。
    ///
    /// 作法：先以 `**` 切段（奇數段為粗體），再於每段內以單個 `*` 切段（奇數段為斜體）。
    /// 標記成對時運作正確；若不成對則退化為原樣文字，不會崩潰。
    private static func applyInlineStyles(to text: String, baseFont: UIFont, textColor: UIColor) -> NSAttributedString {
        let result = NSMutableAttributedString()
        let boldSegments = text.components(separatedBy: "**")

        for (boldIndex, boldSegment) in boldSegments.enumerated() {
            let isBold = boldIndex % 2 == 1

            // 在粗體切段內再處理斜體。
            let italicSegments = boldSegment.components(separatedBy: "*")
            for (italicIndex, italicSegment) in italicSegments.enumerated() {
                guard !italicSegment.isEmpty else { continue }
                let isItalic = italicIndex % 2 == 1
                let font = fontApplying(bold: isBold, italic: isItalic, to: baseFont)
                result.append(NSAttributedString(
                    string: italicSegment,
                    attributes: [.font: font, .foregroundColor: textColor]
                ))
            }
        }
        return result
    }

    /// 依需要在基準字型上疊加粗體 / 斜體 traits。
    private static func fontApplying(bold: Bool, italic: Bool, to baseFont: UIFont) -> UIFont {
        var traits = baseFont.fontDescriptor.symbolicTraits
        if bold { traits.insert(.traitBold) }
        if italic { traits.insert(.traitItalic) }
        guard let descriptor = baseFont.fontDescriptor.withSymbolicTraits(traits) else {
            return baseFont
        }
        return UIFont(descriptor: descriptor, size: baseFont.pointSize)
    }
}
