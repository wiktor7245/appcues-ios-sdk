//
//  AppcuesEmbed.swift
//  AppcuesKit
//
//  Created by James Ellis on 11/30/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation
import SwiftUI

internal struct AppcuesEmbed: View {
    let model: ExperienceComponent.EmbedModel

    @EnvironmentObject var viewModel: ExperienceStepViewModel

    var body: some View {
        EmbedWebView(embed: model.embed)
            .aspectRatio(model.intrinsicSize?.aspectRatio, contentMode: .fill)
            .applyAllAppcues(AppcuesStyle(from: model.style))
    }
}

#if DEBUG
internal struct AppcuesEmbedPreview: PreviewProvider {
    static var previews: some View {
        Group {
            AppcuesEmbed(model: EC.embedVideo)
                .previewLayout(PreviewLayout.sizeThatFits)
                .padding()
        }
    }
}
#endif