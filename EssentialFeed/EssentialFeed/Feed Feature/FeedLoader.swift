//
//  FeedLoader.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-01-14.
//

import Foundation

public enum LoadFeedResult {
    case success([FeedImage])
    case failure(Error)
}

public protocol FeedLoader {
    func load(completion: @escaping (LoadFeedResult) -> Void)
}
