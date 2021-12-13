//
//  ExperienceStepViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import SwiftUI

internal class ExperienceStepViewController: UIViewController {

    let viewModel: ExperienceStepViewModel

    weak var lifecycleHandler: ExperienceStepLifecycleHandler?

    private let contentViewController: UIViewController
    lazy var scrollView = UIScrollView()

    var customScrollInsets: UIEdgeInsets = .zero {
        didSet {
            // Set the insets on `contentViewController` so that sticky views don't cause a loop where they try to
            // inset by the `additionalSafeAreaInsets` they set.
            contentViewController.additionalSafeAreaInsets = customScrollInsets
            scrollView.verticalScrollIndicatorInsets = customScrollInsets
        }
    }

    init(viewModel: ExperienceStepViewModel) {
        self.viewModel = viewModel

        let rootView = ExperienceStepRootView(rootView: viewModel.step.content.view, viewModel: viewModel)
        self.contentViewController = AppcuesHostingController(rootView: rootView)

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        // `scrollView` isn't the root so that things can exist outside the scrolling area.
        view.addSubview(scrollView)
        scrollView.pin(to: view)

        addChild(contentViewController)
        scrollView.addSubview(contentViewController.view)
        contentViewController.view.pin(to: scrollView)
        NSLayoutConstraint.activate([
            contentViewController.view.widthAnchor.constraint(equalTo: scrollView.widthAnchor)
        ])
        contentViewController.didMove(toParent: self)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lifecycleHandler?.stepWillAppear()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lifecycleHandler?.stepDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lifecycleHandler?.stepWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lifecycleHandler?.stepDidDisappear()
    }
}