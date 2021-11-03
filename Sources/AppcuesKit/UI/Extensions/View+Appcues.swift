//
//  View+Appcues.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

extension View {
    func applyAppcues(_ layout: AppcuesLayout, _ style: AppcuesStyle) -> some View {
        self
            .modifier(layout)
            .modifier(style)
            // margin needs to be added after backgrounds/borders
            .ifLet(layout.margin) { view, val in
                view.padding(val)
            }
    }
}