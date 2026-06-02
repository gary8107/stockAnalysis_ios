//
//  DecodableBool.swift
//  AE-MPS
//
//  Created by joanna.hsu on 2021/11/4.
//  Copyright © 2021 AE. All rights reserved.
//

import Foundation

@propertyWrapper
struct DecodableBool: Decodable {
    var wrappedValue: Bool?
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let stringValue = try? container.decode(String.self) {
            switch stringValue.lowercased() {
            case "false": wrappedValue = false
            case "true": wrappedValue = true
            default: wrappedValue = nil
            }
        } else if let intValue = try? container.decode(Int.self) {
            switch intValue {
            case 0: wrappedValue = false
            case 1: wrappedValue = true
            default: wrappedValue = nil
            }
        } else {
            wrappedValue = try? container.decode(Bool.self)
        }
    }
}
