//
//  AppcuesUpdateProfileAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

@available(iOS 13.0, *)
internal class AppcuesUpdateProfileAction: AppcuesExperienceAction {
    struct Config {
        let properties: [String: Any]
    }

    static let type = "@appcues/update-profile"

    private weak var appcues: Appcues?

    let properties: [String: Any]

    required init?(configuration: AppcuesExperiencePluginConfiguration) {
        self.appcues = configuration.appcues

        let config = configuration.decode(Config.self)
        if let properties = config?.properties, !properties.isEmpty {
            self.properties = properties
        } else {
            return nil
        }
    }

    init(appcues: Appcues?, properties: [String: Any]) {
        self.appcues = appcues
        self.properties = properties
    }

    func execute(completion: ActionRegistry.Completion) {
        guard let appcues = appcues else { return completion() }

        let userID = appcues.container.resolve(DataStoring.self).userID
        appcues.identify(userID: userID, properties: properties)
        completion()
    }
}

@available(iOS 13.0, *)
extension AppcuesUpdateProfileAction.Config: Decodable {
    // Custom decoding for this one - we want to just gather up all the key/value
    // pairs from the trait config as raw user property values. We trim the set to
    // only those of supported data types and then store in the resulting properties
    // dictionary
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: DynamicCodingKeys.self)

        var dict: [String: Any] = [:]

        container.allKeys.forEach { key in
            if let boolValue = try? container.decode(Bool.self, forKey: key) {
                dict[key.stringValue] = boolValue
            } else if let stringValue = try? container.decode(String.self, forKey: key) {
                dict[key.stringValue] = stringValue
            } else if let intValue = try? container.decode(Int.self, forKey: key) {
                dict[key.stringValue] = intValue
            } else if let doubleValue = try? container.decode(Double.self, forKey: key) {
                dict[key.stringValue] = doubleValue
            } else {
                // not a supported type
            }
        }

        self.properties = dict
    }
}
