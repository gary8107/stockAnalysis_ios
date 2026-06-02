//
//  Cachable.swift
//  AE-MPS
//
//  Created by Kao Ming-Hsiu on 2019/10/29.
//  Copyright © 2019 AE. All rights reserved.
//

import Moya

struct CacheConfig {
    
    static let `default` = URLCache(memoryCapacity: 0, diskCapacity: 30*1024*1024, diskPath: "default")
}

protocol Cacheable {
    var cachePolicy: NSURLRequest.CachePolicy {get}
}

protocol DynamicCacheable: Cacheable {
    var cached: Bool {get}
}

extension DynamicCacheable {
    var cachePolicy: NSURLRequest.CachePolicy {
        self.cached ? .returnCacheDataElseLoad : .reloadIgnoringLocalAndRemoteCacheData
    }
}

extension Cacheable {
    var cachePolicy: NSURLRequest.CachePolicy {
        return .returnCacheDataElseLoad
    }
}

class CachePlugin: PluginType {
    
    func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        guard let cacheable = target as? Cacheable else { return request }
        var newRequest = request
        newRequest.cachePolicy = cacheable.cachePolicy
        return newRequest
    }
}
