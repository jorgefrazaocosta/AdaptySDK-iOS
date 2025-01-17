//
//  AdaptyAttributionSource.JSON.swift
//  UnitTests
//
//  Created by Aleksei Valiano on 22.11.2022
//  Copyright © 2022 Adapty. All rights reserved.
//

@testable import AdaptySDK

extension AdaptyAttributionSource {
    enum ValidJSON {
        static let all = [adjust, appsflyer, branch, appleSearchAds, custom]
        static let adjust: JSONValue = "adjust"
        static let appsflyer: JSONValue = "appsflyer"
        static let branch: JSONValue = "branch"
        static let appleSearchAds: JSONValue = "apple_search_ads"
        static let custom: JSONValue = "custom"
    }

    enum InvalidJSON {
        static let all = [unknown]
        static let unknown: JSONValue = "unknown"
    }
}
