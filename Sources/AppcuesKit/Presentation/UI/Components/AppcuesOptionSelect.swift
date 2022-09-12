//
//  AppcuesOptionSelect.swift
//  AppcuesKit
//
//  Created by Matt on 2022-08-11.
//  Copyright © 2022 Appcues. All rights reserved.
//

import SwiftUI

@available(iOS 13.0, *)
internal struct AppcuesOptionSelect: View {
    let model: ExperienceComponent.OptionSelectModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        let style = AppcuesStyle(from: model.style)

        VStack(alignment: style.horizontalAlignment, spacing: 0) {
            ExperienceComponent.text(model.label).view

            switch (model.selectMode, model.displayFormat) {
            case (.single, .picker):
                Picker(model.label.text, selection: viewModel.formBinding(for: model.id)) {
                    ForEach(model.options) { option in
                        option.content.view
                            .tag(option.value)
                    }
                }
            case (_, .horizontalList):
                HStack(alignment: .center, spacing: 0) {
                    items
                }
            case (_, .verticalList),
                // fallbacks
                (_, .none), (.multi, .picker):
                VStack(alignment: .leading, spacing: 0) {
                    items
                }
            }
        }
        .setupActions(on: viewModel, for: model.id)
        .applyAllAppcues(style)
    }

    @ViewBuilder var items: some View {
        ForEach(model.options) { option in
            let binding = viewModel.formBinding(for: model.id, value: option.value)
            SelectToggleView(
                selected: binding,
                model: model
            ) {
                if binding.wrappedValue {
                    (option.selectedContent ?? option.content).view
                } else {
                    option.content.view
                }
            }
        }
    }
}
