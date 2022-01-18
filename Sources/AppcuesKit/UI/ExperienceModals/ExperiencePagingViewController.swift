//
//  ExperiencePagingViewController.swift
//  AppcuesKit
//
//  Created by Matt on 2021-11-02.
//  Copyright © 2021 Appcues. All rights reserved.
//

import UIKit

private class ExperiencePagingView: UIView {

    lazy var preferredHeightConstraint: NSLayoutConstraint = {
        var constraint = heightAnchor.constraint(equalToConstant: 0)
        constraint.priority = .defaultLow
        constraint.isActive = true
        return constraint
    }()

    var scrollHandler: NSCollectionLayoutSectionVisibleItemsInvalidationHandler?

    lazy var collectionView: UICollectionView = {
        let section = NSCollectionLayoutSection.fullScreenCarousel()
        section.visibleItemsInvalidationHandler = { [weak self] visibleItems, point, environment in
            self?.scrollHandler?(visibleItems, point, environment)
        }

        let layout = UICollectionViewCompositionalLayout(section: section)

        let view = UICollectionView(frame: .zero, collectionViewLayout: layout)
        view.backgroundColor = .clear
        view.alwaysBounceVertical = false
        view.contentInsetAdjustmentBehavior = .never

        return view
    }()

    var pageControl: UIPageControl = {
        let view = UIPageControl()
        view.translatesAutoresizingMaskIntoConstraints = false
        view.hidesForSinglePage = true
        view.currentPageIndicatorTintColor = .secondaryLabel
        view.pageIndicatorTintColor = .tertiaryLabel
        return view
    }()

    init() {
        super.init(frame: .zero)

        addSubview(collectionView)
        addSubview(pageControl)

        collectionView.pin(to: self)

        NSLayoutConstraint.activate([
            pageControl.centerXAnchor.constraint(equalTo: centerXAnchor),
            pageControl.bottomAnchor.constraint(equalTo: safeAreaLayoutGuide.bottomAnchor)
        ])
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

internal class ExperiencePagingViewController: UIViewController {

    weak var lifecycleHandler: ExperienceContainerLifecycleHandler?

    var targetPageIndex: Int?
    private var currentPageIndex: Int = 0 {
        didSet {
            if currentPageIndex != oldValue {
                lifecycleHandler?.containerNavigated(from: oldValue, to: currentPageIndex)
                pageControl.currentPage = currentPageIndex
            }
        }
    }

    private lazy var pagingView = ExperiencePagingView()
    var pageControl: UIPageControl { pagingView.pageControl }

    let groupID: String?
    private let stepControllers: [UIViewController]

    /// **Note:** `stepControllers` are expected to have a preferredContentSize specified.
    init(stepControllers: [UIViewController], groupID: String?) {
        self.stepControllers = stepControllers
        self.groupID = groupID

        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func loadView() {
        view = pagingView
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        pagingView.scrollHandler = { [weak self] visibleItems, point, environment in
            self?.scrollHandler(visibleItems, point, environment)
        }

        pagingView.collectionView.register(StepPageCell.self, forCellWithReuseIdentifier: StepPageCell.reuseID)
        pagingView.collectionView.dataSource = self
        pagingView.collectionView.delegate = self

        pagingView.pageControl.numberOfPages = stepControllers.count

        pagingView.pageControl.addTarget(self, action: #selector(updateCurrentPage(sender:)), for: .valueChanged)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        lifecycleHandler?.containerWillAppear()

        if let pageIndex = targetPageIndex {
            targetPageIndex = nil
            DispatchQueue.main.async {
                self.goTo(pageIndex: pageIndex, animated: false)
            }
        }
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        lifecycleHandler?.containerDidAppear()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        lifecycleHandler?.containerWillDisappear()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        lifecycleHandler?.containerDidDisappear()
    }

    override func preferredContentSizeDidChange(forChildContentContainer container: UIContentContainer) {
        super.preferredContentSizeDidChange(forChildContentContainer: container)

        // If the current child controller changes it's preferred size, propagate that to the paging view.
        pagingView.preferredHeightConstraint.constant = container.preferredContentSize.height
    }

    @objc
    func updateCurrentPage(sender: UIPageControl) {
        goTo(pageIndex: sender.currentPage, animated: false)
    }

    func goTo(pageIndex: Int, animated: Bool = true) {
        pagingView.collectionView.scrollToItem(
            at: IndexPath(row: pageIndex, section: 0),
            at: .centeredHorizontally,
            animated: animated)
    }

    func scrollHandler(_ visibleItems: [NSCollectionLayoutVisibleItem], _ point: CGPoint, _ environment: NSCollectionLayoutEnvironment) {
        let width = environment.container.contentSize.width

        // Visible items always contains index 0, even when it shouldn't, so filter out pages that aren't actually visible.
        // `collectionView.indexPathsForVisibleItems` would be an option but it's not always correct when jumping without animation.
        let visibleRange = (point.x - width + CGFloat.leastNormalMagnitude)..<(point.x + width)
        let actuallyVisibleItems = visibleItems.filter { visibleRange.contains(CGFloat($0.indexPath.row) * width) }

        let heights: [CGFloat] = actuallyVisibleItems
            .map { stepControllers[$0.indexPath.row].preferredContentSize.height }

        if heights.count == 2 {
            // For a contentHeight value large enough to scroll, this can create a slightly odd animation where the container
            // reaches it's max size too quickly because we're scaling the size as if the full contentHeight can be achieved.
            // TODO: To fix, we'd need to cap the contentHeight values at the max height of the container.
            let heightDiff = heights[1] - heights[0]
            let transitionPercentage = transitionPercentage(itemWidth: width, xOffset: point.x)
            // Set the preferred container height to transition smoothly between the difference in heights.
            pagingView.preferredHeightConstraint.constant = heights[0] + heightDiff * transitionPercentage
        } else {
            if let singleHeight = heights.last {
                pagingView.preferredHeightConstraint.constant = singleHeight
            }

            if let pageIndex = visibleItems.last?.indexPath.row {
                currentPageIndex = pageIndex
            }
        }
    }

    /// Calculate the horizontal scroll progress between any two sibling pages.
    private func transitionPercentage(itemWidth: CGFloat, xOffset: CGFloat) -> CGFloat {
        var percentage = (xOffset.truncatingRemainder(dividingBy: itemWidth)) / itemWidth
        // When the scroll percentage hits exactly 100, it's actually calculated as 0 from the mod operator, so set it to 1
        if percentage == 0 {
            percentage = 1
        }
        return percentage
    }
}

extension ExperiencePagingViewController: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        stepControllers.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StepPageCell.reuseID, for: indexPath)

        if let pageCell = cell as? StepPageCell {
            pageCell.setContent(to: stepControllers[indexPath.row].view)
        }

        return cell
    }

    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let controller = stepControllers[indexPath.row]
        addChild(controller)
        controller.didMove(toParent: self)
    }

    func collectionView(_ collectionView: UICollectionView, didEndDisplaying cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        let controller = stepControllers[indexPath.row]
        controller.willMove(toParent: nil)
        controller.removeFromParent()
    }
}

extension ExperiencePagingViewController {
    class StepPageCell: UICollectionViewCell {

        override init(frame: CGRect) {
            super.init(frame: .zero)
        }

        @available(*, unavailable)
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }

        override func prepareForReuse() {
            super.prepareForReuse()
            contentView.subviews.forEach { $0.removeFromSuperview() }
        }

        func setContent(to view: UIView) {
            contentView.addSubview(view)
            view.pin(to: contentView)
        }
    }
}