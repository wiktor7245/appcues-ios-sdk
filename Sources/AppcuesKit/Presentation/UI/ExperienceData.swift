//
//  ExperienceData.swift
//  AppcuesKit
//
//  Created by Matt on 2022-09-12.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
@dynamicMemberLookup
internal class ExperienceData {
    let model: Experience
    private let formState: FormState

    internal init(experience: Experience) {
        self.model = experience
        self.formState = FormState(experience: experience)
    }

    func state(for stepID: UUID) -> StepState {
        guard let stepState = formState.steps[stepID] else {
            // This will never happen as long as we ask for a valid `stepID`, but to avoid a crash
            // where there's no environmentObject set, return an empty state.
            // If this does get into the UI, the result will be form controls that don't update.
            return StepState(formItems: [:])
        }

        return stepState
    }

    func state(for stepIndex: Experience.StepIndex) -> StepState? {
        guard let stepID = model.steps[safe: stepIndex.group]?.items[safe: stepIndex.item]?.id else { return nil }
        return state(for: stepID)
    }

    subscript<T>(dynamicMember keyPath: KeyPath<Experience, T>) -> T {
        return model[keyPath: keyPath]
    }
}

@available(iOS 13.0, *)
extension ExperienceData {

    enum Validator: Equatable {
        /// The item has some value.
        case nonEmpty
        /// At least the specified number of values have been selected.
        case minSelections(UInt)
        /// At most the specified number of values have been selected.
        case maxSelections(UInt)

        @available(iOS 13.0, *)
        func isSatisfied(value: ExperienceData.FormItem.ValueType) -> Bool {
            switch (self, value) {
            case (.nonEmpty, _), (.minSelections, .single):
                return value.isSet
            case (.maxSelections, .single):
                // Case should never apply, but logically it's always valid
                return true
            case let (.minSelections(min), .multi(set, _)):
                return set.count >= min
            case let (.maxSelections(max), .multi(set, _)):
                return set.count <= max
            }
        }
    }

    class FormState {
        var steps: [UUID: StepState] = [:]

        init(experience: Experience) {
            experience.steps.forEach { step in
                step.items.forEach { item in
                    steps[item.id] = StepState(formItems: item.content.formComponents)
                }
            }
        }
    }

    class StepState: ObservableObject {
        @Published var formItems: [UUID: FormItem]

        var stepFormIsComplete: Bool {
            !formItems.contains { !$0.value.isSatisfied }
        }

        init(formItems: [UUID: FormItem]) {
            self.formItems = formItems
        }

        func formBinding(for key: UUID) -> Binding<String> {
            return .init(
                get: { self.formItems[key]?.getValue() ?? "" },
                set: {
                    self.formItems[key]?.setValue($0)
                })
        }

        func formBinding(for key: UUID, value: String) -> Binding<Bool> {
            return .init(
                get: { self.formItems[key]?.contains(searchValue: value) ?? false },
                set: { _ in
                    self.formItems[key]?.setValue(value)
                })
        }
    }

    struct FormItem: Equatable {
        enum ValueType: Equatable {
            case single(String)
            case multi([String], max: UInt?)

            var isSet: Bool {
                switch self {
                case .single(let value):
                    return !value.isEmpty
                case .multi(let values, _):
                    return !values.isEmpty
                }
            }

            var value: String {
                switch self {
                case .single(let value):
                    return value
                case .multi(let values, _):
                    return values.joined(separator: ",")
                }
            }
        }

        fileprivate let type: String
        fileprivate let label: String
        fileprivate var underlyingValue: ValueType
        fileprivate let validators: [Validator]
        fileprivate let required: Bool

        var isSatisfied: Bool {
            return !validators.contains { !$0.isSatisfied(value: underlyingValue) }
        }

        init(model: ExperienceComponent.TextInputModel) {
            self.type = "textInput"
            self.label = model.label.text
            self.underlyingValue = .single(model.defaultValue ?? "")
            self.validators = model.validators()
            self.required = model.required ?? false
        }

        init(model: ExperienceComponent.OptionSelectModel) {
            self.type = "optionSelect"
            self.label = model.label.text
            switch model.selectMode {
            case .single:
                self.underlyingValue = .single(model.defaultValue?.first ?? "")
            case .multi:
                self.underlyingValue = .multi(model.defaultValue ?? [], max: model.trueMaxSelections)
            }
            self.validators = model.validators()
            self.required = model.trueMinSelections > 0
        }

        func getValue() -> String {
            underlyingValue.value
        }

        mutating func setValue(_ newValue: String) {
            switch underlyingValue {
            case .single:
                underlyingValue = .single(newValue)
            case .multi(var existingValues, let maxSelections):
                if existingValues.contains(newValue) {
                    existingValues = existingValues.filter { $0 != newValue }
                } else if let maxSelections = maxSelections {
                    if existingValues.count < maxSelections {
                        existingValues.append(newValue)
                    } else {
                        // Would be selecting more than the max, so no change.
                    }
                } else {
                    existingValues.append(newValue)
                }
                underlyingValue = .multi(existingValues, max: maxSelections)
            }
        }

        func contains(searchValue: String) -> Bool {
            switch underlyingValue {
            case .single(let value):
                return value == searchValue
            case .multi(let existingValues, _):
                return existingValues.contains(searchValue)
            }
        }
    }
}

@available(iOS 13.0, *)
extension ExperienceData.StepState {
    func formattedAsProfileUpdate() -> [String: Any] {
        var update: [String: Any] = [:]

        formItems.forEach { _, item in
            update["_appcuesForm_\(item.label.asSlug)"] = item.getValue()
        }

        return update
    }

    func formattedAsDebugData() -> [(title: String, value: String)] {
        return formItems.map { _, formItem in
            (formItem.label, formItem.getValue())
        }
    }
}

@available(iOS 13.0, *)
extension ExperienceData.StepState: Encodable {
    enum ItemKeys: CodingKey {
        case fieldId, fieldType, fieldRequired, value, label
    }

    func encode(to encoder: Encoder) throws {
        var container = encoder.unkeyedContainer()

        try formItems.forEach { id, formItem in
            var itemContainer = container.nestedContainer(keyedBy: ItemKeys.self)
            try itemContainer.encode(id, forKey: .fieldId)
            try itemContainer.encode(formItem.type, forKey: .fieldType)
            try itemContainer.encode(formItem.required, forKey: .fieldRequired)
            try itemContainer.encode(formItem.getValue(), forKey: .value)
            try itemContainer.encode(formItem.label, forKey: .label)
        }
    }
}

@available(iOS 13.0, *)
extension ExperienceData.StepState: Equatable {
    static func == (lhs: ExperienceData.StepState, rhs: ExperienceData.StepState) -> Bool {
        lhs.formItems == rhs.formItems
    }
}

@available(iOS 13.0, *)
extension ExperienceComponent.TextInputModel {
    func validators() -> [ExperienceData.Validator] {
        var validators: [ExperienceData.Validator] = []

        if required == true {
            validators.append(.nonEmpty)
        }

        return validators
    }
}

@available(iOS 13.0, *)
extension ExperienceComponent.OptionSelectModel {

    /// The actual minimum number of selections (accounting for the full model state)	.
    var trueMinSelections: UInt {
        min((minSelections ?? 0), UInt(options.count))
    }

    /// The actual maximum number of selections (accounting for the full model state).
    var trueMaxSelections: UInt? {
        guard let maxSelections = maxSelections else { return nil }

        return max(trueMinSelections, maxSelections)
    }

    func validators() -> [ExperienceData.Validator] {
        var validators: [ExperienceData.Validator] = []

        if trueMinSelections > 0 {
            switch selectMode {
            case .single:
                validators.append(.minSelections(1))
            case .multi:
                validators.append(.minSelections(trueMinSelections))
            }
        }

        if let maxSelections = trueMaxSelections {
            validators.append(.maxSelections(maxSelections))
        }

        return validators
    }
}

private extension String {
    private static let slugSafeCharacters = CharacterSet(charactersIn: "0123456789ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz-")

    var asSlug: String {
        guard let latin = self.applyingTransform(StringTransform("Any-Latin; Latin-ASCII; Lower;"), reverse: false) else { return self }

        let urlComponents = latin.components(separatedBy: String.slugSafeCharacters.inverted)
        let result = urlComponents.filter { !$0.isEmpty }.joined(separator: "-")

        return result
    }
}