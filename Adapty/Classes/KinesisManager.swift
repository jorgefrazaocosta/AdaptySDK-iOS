//
//  KinesisManager.swift
//  Adapty
//
//  Created by sugaroff on 11/5/19.
//  Copyright © 2019 Adapty. All rights reserved.
//

import CommonCrypto
import Foundation

class KinesisManager {
    enum EventType: String {
        case live
        case paywallShowed = "paywall_showed"
    }

    enum Constants {
        static let streamName = "adapty-data-pipeline-prod"
        static let region = "us-east-1"
        static let hmacShaTypeString = "AWS4-HMAC-SHA256"
        static let serviceType = "kinesis"
        static let aws4Request = "aws4_request"
        static let amzTarget = "Kinesis_20131202.PutRecords"
        static let contentType = "application/x-amz-json-1.1"
    }

    static let shared = KinesisManager()
    private init() {}

    private let sessionID = UUID().stringValue
    private var cachedEvents: [[String: String]] {
        get {
            return DefaultsManager.shared.cachedEvents
        }
        set {
            DefaultsManager.shared.cachedEvents = newValue
        }
    }

    private var profileId: String {
        DefaultsManager.shared.profileId
    }

    private var installation: InstallationModel? {
        DefaultsManager.shared.installation
    }

    func trackEvent(_ eventType: EventType, params: [String: String]? = nil, completion: ErrorCompletion? = nil) {
        guard let installation = installation else {
            let error = AdaptyError.missingParam("AdaptySDK – can't find cached installation")
            LoggerManager.logError(error)
            DispatchQueue.main.async {
                completion?(error)
            }
            return
        }

        if DefaultsManager.shared.externalAnalyticsDisabled {
            let error = AdaptyError.analyticsDisabled
            if eventType == .paywallShowed {
                LoggerManager.logMessage(error.localizedDescription)
            }

            DispatchQueue.main.async {
                completion?(error)
            }
            return
        }

        // Event parameters
        var eventParams = [String: String]()
        eventParams["event_name"] = eventType.rawValue
        eventParams["event_id"] = UUID().stringValue
        eventParams["profile_id"] = profileId
        eventParams["profile_installation_meta_id"] = installation.profileInstallationMetaId
        eventParams["session_id"] = sessionID
        eventParams["created_at"] = Date().iso8601Value
        eventParams["platform"] = UserProperties.platform
        if let params = params {
            for (key, value) in params {
                eventParams[key] = value
            }
        }

        cachedEvents.append(eventParams)

        DispatchQueue.global(qos: .background).async {
            self.syncEvents(profileInstallationMetaID: installation.profileInstallationMetaId, secretSigningKey: installation.iamSecretKey, accessKeyId: installation.iamAccessKeyId, sessionToken: installation.iamSessionToken, completion: completion)
        }
    }

    private func syncEvents(profileInstallationMetaID: String, secretSigningKey: String, accessKeyId: String, sessionToken: String, completion: ErrorCompletion? = nil) {
        let currentCachedEvents = cachedEvents

        let eventsDataBase64 = currentCachedEvents.map { try! JSONEncoder().encode($0).base64EncodedString() }

        // Kinesis request parameters
        var requestParams = Parameters()
        let kinesisRecords = eventsDataBase64.map { ["Data": $0, "PartitionKey": profileInstallationMetaID] }
        requestParams["Records"] = kinesisRecords
        requestParams["StreamName"] = Constants.streamName

        let router = Router.trackEvent(params: requestParams)
        var urlRequest = try! router.asURLRequest()

        urlRequest = KinesisManager.sign(request: urlRequest, secretSigningKey: secretSigningKey, accessKeyId: accessKeyId, sessionToken: sessionToken)!

        RequestManager.shared.request(urlRequest: urlRequest, router: router) { (result: Result<JSONModel, AdaptyError>, _) in
            switch result {
            case .success:
                let updatedCachedEvents = Set(self.cachedEvents).subtracting(currentCachedEvents)
                self.cachedEvents = Array(updatedCachedEvents)
                completion?(nil)
            case let .failure(error):
                completion?(error)
            }
        }
    }
}

private extension KinesisManager {
    private static let iso8601DateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .iso8601)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateFormat = "yyyyMMdd'T'HHmmssXXXXX"
        return formatter
    }()

    private static func iso8601Date() -> (full: String, short: String) {
        let date = iso8601DateFormatter.string(from: Date())
        let index = date.index(date.startIndex, offsetBy: 8)
        let shortDate = String(date[..<index])
        return (full: date, short: shortDate)
    }

    private static func hmacStringToSign(stringToSign: String, secretSigningKey: String, shortDateString: String) -> String? {
        let k1 = "AWS4" + secretSigningKey
        let signature = HMAC(secret: k1, algorithm: .sha256)
            .authenticatedChain(with: shortDateString)
            .authenticatedChain(with: Constants.region)
            .authenticatedChain(with: Constants.serviceType)
            .authenticatedChain(with: Constants.aws4Request)
            .authenticate(with: stringToSign)
        return signature.toHexString()
    }

    private static func sign(request: URLRequest, secretSigningKey: String, accessKeyId: String, sessionToken: String) -> URLRequest? {
        var signedRequest = request
        let date = iso8601Date()
        var body: String = ""
        if let httpBody = signedRequest.httpBody, let stringBody = String(data: httpBody, encoding: .utf8) {
            body = stringBody
        }

        guard let url = signedRequest.url, let host = url.host else { return .none }

        signedRequest.setValue(sessionToken, forHTTPHeaderField: "X-Amz-Security-Token")
        signedRequest.setValue(host, forHTTPHeaderField: "Host")
        signedRequest.setValue(date.full, forHTTPHeaderField: "X-Amz-Date")
        signedRequest.setValue(Constants.amzTarget, forHTTPHeaderField: "X-Amz-Target")
        signedRequest.setValue(Constants.contentType, forHTTPHeaderField: "Content-Type")

        // ************* TASK 1: CREATE A CANONICAL REQUEST *************

        guard let headers = signedRequest.allHTTPHeaderFields, let method = signedRequest.httpMethod
        else { return .none }

        let signedHeaders = headers.map { $0.key.lowercased() }.sorted().joined(separator: ";")
        let canonicalPath = url.path.isEmpty ? "/" : url.path
        let canonicalQuery = url.query ?? ""
        let canonicalHeaders = headers.map { $0.key.lowercased() + ":" + $0.value }.sorted().joined(separator: "\n")
        let canonicalRequest = [method, canonicalPath, canonicalQuery, canonicalHeaders, "", signedHeaders, body.sha256()].joined(separator: "\n")

        // ************* TASK 2: CREATE THE STRING TO SIGN *************

        let credential = [date.short, Constants.region, Constants.serviceType, Constants.aws4Request].joined(separator: "/")

        let stringToSign = [Constants.hmacShaTypeString, date.full, credential, canonicalRequest.sha256()].joined(separator: "\n")

        // ************* TASK 3: CALCULATE THE SIGNATURE *************

        guard let signature = hmacStringToSign(stringToSign: stringToSign, secretSigningKey: secretSigningKey, shortDateString: date.short)
        else { return .none }

        // ************* TASK 4: ADD SIGNING INFORMATION TO THE REQUEST *************

        let authorization = Constants.hmacShaTypeString + " Credential=" + accessKeyId + "/" + credential + ", SignedHeaders=" + signedHeaders + ", Signature=" + signature
        signedRequest.addValue(authorization, forHTTPHeaderField: "Authorization")

        return signedRequest
    }
}
