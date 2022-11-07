//
//    Profile.Subscription.swift
//  Adapty
//
//  Created by Aleksei Valiano on 24.09.2022.
//

import Foundation

extension Profile {
    /// Information about the user's subscription.
    public struct Subscription {
        /// A store of the purchase.
        ///
        /// Possible values:
        /// - `app_store`
        /// - `play_store`
        /// - `adapty`
        public let store: String

        /// An identifier of a product in a store that unlocked this subscription.
        public let vendorProductId: String

        /// A transaction id of a purchase in a store that unlocked this subscription.
        public let vendorTransactionId: String

        /// An original transaction id of the purchase in a store that unlocked this subscription. For auto-renewable subscription, this will be an id of the first transaction in this subscription.
        public let vendorOriginalTransactionId: String

        /// True if the subscription is active
        public let isActive: Bool

        /// True if the subscription is active for a lifetime (no expiration date)
        public let isLifetime: Bool

        /// Time when the subscription was activated.
        public let activatedAt: Date

        /// Time when the subscription was renewed. It can be `nil` if the purchase was first in chain or it is non-renewing subscription.
        public let renewedAt: Date?

        /// Time when the access level will expire (could be in the past and could be `nil` for lifetime access).
        public let expiresAt: Date?

        /// Time when the subscription has started (could be in the future).
        public let startsAt: Date?

        /// Time when the auto-renewable subscription was cancelled. Subscription can still be active, it means that auto-renewal is turned off. Would be `nil` if a user reactivates the subscription.
        public let unsubscribedAt: Date?

        /// Time when a billing issue was detected. Subscription can still be active.
        public let billingIssueDetectedAt: Date?

        /// Whether the auto-renewable subscription is in a grace period.
        public let isInGracePeriod: Bool

        /// `true` if the product was purchased in a sandbox environment.
        public let isSandbox: Bool

        /// `true` if the purchase was refunded.
        public let isRefund: Bool

        /// `true` if the auto-renewable subscription is set to renew
        public let willRenew: Bool

        /// A type of an active introductory offer. If the value is not null, it means that the offer was applied during the current subscription period.
        ///
        /// Possible values:
        /// - `free_trial`
        /// - `pay_as_you_go`
        /// - `pay_up_front`
        public let activeIntroductoryOfferType: String?

        /// A type of an active promotional offer. If the value is not null, it means that the offer was applied during the current subscription period.
        ///
        /// Possible values:
        /// - `free_trial`
        /// - `pay_as_you_go`
        /// - `pay_up_front`
        public let activePromotionalOfferType: String?

        /// An id of active promotional offer.
        public let activePromotionalOfferId: String?

        /// A reason why a subscription was cancelled.
        ///
        /// Possible values:
        /// - `voluntarily_cancelled`
        /// - `billing_error`
        /// - `price_increase`
        /// - `product_was_not_available`
        /// - `refund`
        /// - `upgraded`
        /// - `unknown`
        public let cancellationReason: String?
    }
}

extension Profile.Subscription: Equatable {}

extension Profile.Subscription: CustomStringConvertible {
    public var description: String {
        "(isActive: \(isActive), vendorProductId: \(vendorProductId), store: \(store), activatedAt: \(activatedAt), "
            + (renewedAt == nil ? "" : "renewedAt: \(renewedAt!), ")
            + (expiresAt == nil ? "" : "expiresAt: \(expiresAt!), ")
            + (startsAt == nil ? "" : "startsAt: \(startsAt!), ")
            + "isLifetime: \(isLifetime), "
            + (activeIntroductoryOfferType == nil ? "" : "activeIntroductoryOfferType: \(activeIntroductoryOfferType!), ")
            + (activePromotionalOfferType == nil ? "" : "activePromotionalOfferType: \(activePromotionalOfferType!), ")
            + (activePromotionalOfferId == nil ? "" : "activePromotionalOfferId: \(activePromotionalOfferId!), ")
            + "willRenew: \(willRenew), isInGracePeriod: \(isInGracePeriod), "
            + (unsubscribedAt == nil ? "" : "unsubscribedAt: \(unsubscribedAt!), ")
            + (billingIssueDetectedAt == nil ? "" : "billingIssueDetectedAt: \(billingIssueDetectedAt!), ")
            + "isSandbox: \(isSandbox), vendorTransactionId: \(vendorTransactionId), vendorOriginalTransactionId: \(vendorOriginalTransactionId), "
            + (cancellationReason == nil ? "" : "cancellationReason: \(cancellationReason!), ")
            + "isRefund: \(isRefund))"
    }
}

extension Profile.Subscription: Codable {
    enum CodingKeys: String, CodingKey {
        case isActive = "is_active"
        case vendorProductId = "vendor_product_id"
        case vendorTransactionId = "vendor_transaction_id"
        case vendorOriginalTransactionId = "vendor_original_transaction_id"
        case store
        case activatedAt = "activated_at"
        case renewedAt = "renewed_at"
        case expiresAt = "expires_at"
        case isLifetime = "is_lifetime"
        case activeIntroductoryOfferType = "active_introductory_offer_type"
        case activePromotionalOfferType = "active_promotional_offer_type"
        case activePromotionalOfferId = "active_promotional_offer_id"
        case willRenew = "will_renew"
        case isInGracePeriod = "is_in_grace_period"
        case unsubscribedAt = "unsubscribed_at"
        case billingIssueDetectedAt = "billing_issue_detected_at"
        case startsAt = "starts_at"
        case cancellationReason = "cancellation_reason"
        case isRefund = "is_refund"
        case isSandbox = "is_sandbox"
    }
}