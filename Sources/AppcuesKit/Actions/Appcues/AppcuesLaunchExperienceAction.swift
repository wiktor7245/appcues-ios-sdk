//
//  AppcuesLaunchExperienceAction.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-03.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal struct AppcuesLaunchExperienceAction: ExperienceAction {
    static let type = "@appcues/launch-experience"

    let experienceID: String

    init?(config: [String: Any]?) {
        if let experienceID = config?["experienceID"] as? String {
            self.experienceID = experienceID
        } else {
            return nil
        }
    }

    func execute(inContext appcues: Appcues) {
        appcues.show(contentID: experienceID)
    }
}