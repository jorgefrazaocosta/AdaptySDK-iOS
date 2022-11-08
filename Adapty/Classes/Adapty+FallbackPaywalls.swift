//
//  Adapty+Events.swift
//  Adapty
//
//  Created by Aleksei Valiano on 24.09.2022.
//

import Foundation

extension Adapty.Configuration {
    static var fallbackPaywalls: FallbackPaywalls?
}

extension Adapty {
    /// To set fallback paywalls, use this method. You should pass exactly the same payload you're getting from Adapty backend. You can copy it from Adapty Dashboard.
    ///
    /// Adapty allows you to provide fallback paywalls that will be used when a user opens the app for the first time and there's no internet connection. Or in the rare case when Adapty backend is down and there's no cache on the device.
    ///
    /// Read more on the [Adapty Documentation](https://docs.adapty.io/v2.0.0/docs/ios-displaying-products#fallback-paywalls)
    ///
    /// - Parameters:
    ///   - paywalls: a JSON representation of your paywalls/products list in the exact same format as provided by Adapty backend.
    ///   - completion: Result callback.
    public static func setFallbackPaywalls(_ paywalls: Data, _ completion: AdaptyErrorCompletion? = nil) {
        async(completion) { completion in
            do {
                Configuration.fallbackPaywalls = try FallbackPaywalls(from: paywalls)
            } catch {
                completion(AdaptyError.decodingFallback(error))
                return
            }
            completion(nil)
        }
    }
}

extension PaywallsCache {
    func getPaywallWithFallback(byId id: String) -> AdaptyPaywall? {
        let fallback = Adapty.Configuration.fallbackPaywalls?.paywalls[id]
        guard let cache = getPaywall(byId: id)?.value else { return fallback }
        guard let fallback = fallback else { return cache }
        return cache.version > fallback.version ? cache : fallback
    }
}

extension ProductsCache {
    func getProductWithFallback(byId id: String) -> BackendProduct? {
        let fallback = Adapty.Configuration.fallbackPaywalls?.products[id]
        guard let cache = getProduct(byId: id) else { return fallback }
        guard let fallback = fallback else { return cache }
        return cache.version > fallback.version ? cache : fallback
    }

    func getProductsWithFallback(byIds ids: [String]) -> [BackendProduct] {
        ids.compactMap { getProductWithFallback(byId: $0) }
    }
}

extension ProductVendorIdsCache {
    var allProductVendorIdsWithFallback: Set<String> {
        Set(allProductVendorIds?.value ?? []).union(Adapty.Configuration.fallbackPaywalls?.allProductVendorIds ?? [])
    }
}
