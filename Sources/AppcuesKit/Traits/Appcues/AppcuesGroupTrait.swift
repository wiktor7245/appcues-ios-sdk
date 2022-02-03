//
//  AppcuesGroupTrait.swift
//  AppcuesKit
//
//  Created by Matt on 2022-01-31.
//  Copyright © 2022 Appcues. All rights reserved.
//

import Foundation

internal class AppcuesGroupTrait: GroupingTrait {
    static var type: String = "@appcues/group"

    let groupID: String?

    required init?(config: [String: Any]?) {
        self.groupID = config?["groupID"] as? String
    }

    func join(initialStep stepIndex: Int, in experience: Experience) -> [Experience.Step] {
        let modalGroupID = experience.steps[stepIndex].traits.groupID
        return experience.steps.filter { $0.traits.groupID == modalGroupID }
    }
}