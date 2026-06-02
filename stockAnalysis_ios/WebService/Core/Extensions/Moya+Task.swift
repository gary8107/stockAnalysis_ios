//
//  Moya+Task.swift
//  AE-YABO
//
//  Created by joanna.hsu on 2020/2/20.
//  Copyright © 2020 Gary.Lin. All rights reserved.
//

import Foundation
import Moya
import Alamofire

extension Task {
    public static func requestQueryEncodable<Q: Encodable>(_ encodable: Q, dateEncodingStrategy: JSONEncoder.DateEncodingStrategy = .deferredToDate) -> Task {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = dateEncodingStrategy
        
        guard
            let data = try? encoder.encode(encodable),
            let parameters = try? JSONSerialization.jsonObject(with: data, options: []),
            let flatParameters = parameters as? [String: Any] else {
                return .requestPlain
        }
        
        return Task.requestParameters(parameters: flatParameters, encoding: URLEncoding.default)
    }
}
