//
//  ContentBlock.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/10.
//

import Foundation

/// 內容區塊的「中性」表示法，給渲染元件（ContentBlocksView）使用。
///
/// 設計取捨（為什麼這樣做）：
/// - 刻意不直接吃 web service 的 `Block` 型別，讓 UI 元件與後端 model 解耦。
///   呼叫端（對照頁、分析師頁…）各自把自己的 model 對應成 `ContentBlock` 再餵進來，
///   元件就能在不同資料來源間重用，也方便單獨測試。
enum ContentBlock {
    /// 一段 markdown 文字（支援 **粗體**、*斜體*、# 標題、- 清單、連結文字）。
    case markdown(String)
    /// 一個表格：第一列為表頭，其餘為資料列。
    case table(headers: [String], rows: [[String]])
}
