//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-02-12.
//

import Foundation

public enum RetrieveCachedFeedResult {
    case empty
    case failure(Error)
    case success(feed: [LocalFeedImage], timeStamp: Date)
}

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    typealias RetrivalCompletion = (RetrieveCachedFeedResult) -> Void
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func saveCacheFeed(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion)
    func retrieve(completion: @escaping RetrivalCompletion)
}
