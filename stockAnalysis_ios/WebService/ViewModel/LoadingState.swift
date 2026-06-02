//
//  LoadingState.swift
//
//  通用的非同步載入狀態，給 ViewModel 對外表達 UI 狀態用。
//

import Foundation

enum LoadingState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(Error)
}
