//
//  ExperienceLoader.swift
//  AppcuesKit
//
//  Created by James Ellis on 10/28/21.
//  Copyright © 2021 Appcues. All rights reserved.
//

import Foundation

internal protocol ExperienceLoading {
    func load(experienceID: String, published: Bool, completion: ((Result<Void, Error>) -> Void)?)
}

internal class ExperienceLoader: ExperienceLoading {

    private let networking: Networking
    private let experienceRenderer: ExperienceRendering

    init(container: DIContainer) {
        self.networking = container.resolve(Networking.self)
        self.experienceRenderer = container.resolve(ExperienceRendering.self)
    }

    func load(experienceID: String, published: Bool, completion: ((Result<Void, Error>) -> Void)?) {

        let endpoint = published ?
            APIEndpoint.content(experienceID: experienceID) :
            APIEndpoint.preview(experienceID: experienceID)

        networking.get(
            from: endpoint
        ) { [weak self] (result: Result<Experience, Error>) in
            switch result {
            case .success(let experience):
                self?.experienceRenderer.show(experience: experience, published: published, completion: completion)
            case .failure(let error):
                completion?(.failure(error))
            }
        }
    }
}
