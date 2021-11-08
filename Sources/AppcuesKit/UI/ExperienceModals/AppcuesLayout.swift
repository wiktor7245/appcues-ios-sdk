//
//  AppcuesLayout.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal struct AppcuesLayout: ViewModifier {
    let padding: EdgeInsets
    let margin: EdgeInsets
    let spacing: CGFloat?
    let height: CGFloat?
    let width: CGFloat?
    let fillWidth: Bool

    let alignment: Alignment
    let horizontalAlignment: HorizontalAlignment
    let verticalAlignment: VerticalAlignment

    init(from model: ExperienceComponent.Layout?) {
        self.padding = EdgeInsets(
            top: model?.paddingTop ?? 0,
            leading: model?.paddingLeading ?? 0,
            bottom: model?.paddingBottom ?? 0,
            trailing: model?.paddingTrailing ?? 0)
        self.margin = EdgeInsets(
            top: model?.marginTop ?? 0,
            leading: model?.marginLeading ?? 0,
            bottom: model?.marginBottom ?? 0,
            trailing: model?.marginTrailing ?? 0)
        self.spacing = CGFloat(model?.spacing)
        self.height = CGFloat(model?.height)

        if let width = model?.width, width > 0 {
            self.width = CGFloat(width)
        } else {
            self.width = nil
        }
        self.fillWidth = model?.width?.isEqual(to: -1) ?? false

        self.alignment = Alignment(string: model?.alignment) ?? .center
        self.horizontalAlignment = HorizontalAlignment(string: model?.alignment) ?? .center
        self.verticalAlignment = VerticalAlignment(string: model?.alignment) ?? .center
    }

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .frame(width: width, height: height)
            .if(fillWidth) { view in
                view.frame(maxWidth: .infinity)
            }
    }
}
