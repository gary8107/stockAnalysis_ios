//
//  YearMonth.swift
//  stockAnalysis_ios
//
//  Created by WH-Gary on 2026/6/9.
//

import Foundation

/// 以「年 + 月」為單位的輕量值型別，用來把一堆日期分組與排序。
///
/// 設計為 `Comparable`，月份排序可直接用 `>` / `<`（先比年、再比月），
/// 同時是 `Hashable`，方便當作 `Dictionary` 分組的 key。
struct YearMonth: Hashable, Comparable {
    let year: Int
    let month: Int

    static func < (lhs: YearMonth, rhs: YearMonth) -> Bool {
        if lhs.year != rhs.year { return lhs.year < rhs.year }
        return lhs.month < rhs.month
    }
}
