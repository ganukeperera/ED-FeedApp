//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-01-14.
//

import Foundation

public enum LoadFeedResult<Error: Swift.Error> {
    case success([FeedItem])
    case failure(Error)
}

extension LoadFeedResult: Equatable where Error: Equatable {}

protocol FeedLoader {
    func loadFeed(completion: @escaping (LoadFeedResult<Error>) -> Void)
}
