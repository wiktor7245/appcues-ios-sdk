//
//  ExperienceStepViewModel.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-05.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal class ExperienceStepViewModel: ObservableObject {

    enum ActionType: String {
        case tap
        case longPress
    }

    let step: Experience.Step.Child
    let enableTextScaling: Bool
    private let actions: [UUID: [Experience.Action]]
    private let actionRegistry: ActionRegistry?
    private let renderContext: RenderContext
    private weak var appcues: Appcues?

    init(
        step: Experience.Step.Child,
        actionRegistry: ActionRegistry,
        renderContext: RenderContext,
        config: Appcues.Config?,
        appcues: Appcues?
    ) {
        self.step = step
        // Update the action list to be keyed by the UUID.
        self.actions = step.actions.reduce(into: [:]) { dict, item in
            guard let uuidKey = UUID(uuidString: item.key) else { return }
            dict[uuidKey] = item.value
        }
        self.actionRegistry = actionRegistry
        self.renderContext = renderContext
        self.appcues = appcues
        self.enableTextScaling = config?.enableTextScaling ?? false
    }

    // Create an empty view model for contexts that require an `ExperienceStepViewModel` but aren't in a step context.
    init(renderContext: RenderContext, appcues: Appcues?) {
        self.step = Experience.Step.Child(
            id: UUID(),
            type: "",
            traits: [],
            actions: [:],
            content: .spacer(ExperienceComponent.SpacerModel(
                id: UUID(),
                spacing: nil,
                style: nil
            ))
        )
        self.actions = [:]
        self.actionRegistry = nil
        self.renderContext = renderContext
        self.appcues = appcues
        self.enableTextScaling = false
    }

    func enqueueActions(_ actions: [Experience.Action], type: String, viewDescription: String?) {
        actionRegistry?.enqueue(
            actionModels: actions,
            level: .step,
            renderContext: renderContext,
            interactionType: type,
            viewDescription: viewDescription
        )
    }

    func actions(for id: UUID) -> [ActionType?: [Experience.Action]] {
        // An unknown trigger value will get lumped into Dictionary[nil] and be ignored.
        Dictionary(grouping: actions[id] ?? []) { ActionType(rawValue: $0.trigger) }
    }

    func customComponent(for model: ExperienceComponent.CustomComponentModel) -> CustomComponentData? {
        let customComponentData = Appcues.customComponentRegistry.customComponent(
            for: model,
            renderContext: renderContext,
            appcuesInstance: appcues
        )
        customComponentData?.actionController.actions = actions[model.id]
        return customComponentData
    }
}

@available(iOS 13.0, *)
extension ExperienceComponent {
    /// Recursively get all the form components in the `ExperienceContent`.
    var formComponents: [UUID: ExperienceData.FormItem] {
        var components: [UUID: ExperienceData.FormItem] = [:]

        switch self {
        case .text, .button, .image, .spacer, .embed, .customComponent:
            break
        case .stack(let model):
            model.items.forEach {
                components.merge($0.formComponents, uniquingKeysWith: { first, _ in first })
            }
        case .box(let model):
            model.items.forEach {
                components.merge($0.formComponents, uniquingKeysWith: { first, _ in first })
            }
        case .textInput(let model):
            components[model.id] = .init(model: model)
        case .optionSelect(let model):
            components[model.id] = .init(model: model)
        }

        return components
    }
}
