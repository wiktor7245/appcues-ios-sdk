//
//  DebugViewModel.swift
//  AppcuesKit
//
//  Created by Matt on 2021-10-29.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal class DebugViewModel: ObservableObject {
    let accountID: String
    @Published var currentUserID: String?
    @Published private(set) var events: [LoggedEvent] = []
    @Published private(set) var trackingPages = false

    var statusItems: [StatusItem] {
        return [
            StatusItem(verified: true, title: "Installed", subtitle: "Account ID: \(accountID)"),
            StatusItem(verified: true, title: "Connected to Appcues", subtitle: nil),
            StatusItem(verified: trackingPages, title: "Tracking Pages", subtitle: nil),
            StatusItem(verified: true, title: "User Identified", subtitle: "User ID: \(currentUserID ?? "?")")
        ]
    }

    init(accountID: String, currentUserID: String?) {
        self.accountID = accountID
        self.currentUserID = currentUserID
    }

    func addEvent(_ event: LoggedEvent) {
        trackingPages = trackingPages || event.type == .screen
        events.append(event)
    }
}

extension DebugViewModel {
    struct StatusItem: Identifiable {
        let id = UUID()
        let verified: Bool
        let title: String
        let subtitle: String?
    }

    struct LoggedEvent: Identifiable {
        typealias Pair = (title: String, value: String?)

        let id = UUID()
        let timestamp: Date
        let type: EventType
        let name: String
        let properties: [String: Any]?

        var eventDetailItems: [Pair] {
            [
                ("Type", type.description),
                ("Name", name),
                ("Timestamp", "\(timestamp)")
            ]
        }

        var eventProperties: [(title: String, items: [Pair])]? {
            guard var properties = properties else { return nil }

            var groups: [(title: String, items: [Pair])] = []

            // flatten the nested `_identity` auto-properties into individual top level items.
            let autoProps = (properties["_identity"] as? [String: Any] ?? [:])
                .sorted { $0.key > $1.key }
                .map { ($0.key, String(describing: $0.value)) }
            properties["_identity"] = nil

            let userProps = properties
                .sorted { $0.key > $1.key }
                .map { ($0.key, String(describing: $0.value)) }

            if !userProps.isEmpty {
                groups.append(("Properties", userProps))
            }

            if !autoProps.isEmpty {
                groups.append(("Identity Auto-properties", autoProps))
            }

            return groups
        }

        init(from update: TrackingUpdate) {
            self.timestamp = update.timestamp
            self.properties = update.properties

            switch update.type {
            case .event("appcues:flow_attempted"):
                self.type = .experience
                self.name = (properties?["flowName"] as? String) ?? "Flow"
            case let .event(name):
                self.type = .event
                self.name = name
            case let .screen(title):
                self.type = .screen
                self.name = title
            case .profile:
                self.type = .profile
                self.name = "Profile Update"
            }
        }
    }
}

extension DebugViewModel.LoggedEvent {
    enum EventType: CustomStringConvertible {
        case screen
        case event
        case profile
        case experience

        var description: String {
            switch self {
            case .screen: return "Screen"
            case .event: return "Event"
            case .profile: return "User Profile"
            case .experience: return "Experience"
            }
        }

        var symbolName: String {
            switch self {
            case .screen: return "rectangle.portrait.on.rectangle.portrait"
            case .event: return "hand.tap"
            case .profile: return "person"
            case .experience: return "wand.and.stars"
            }
        }
    }
}