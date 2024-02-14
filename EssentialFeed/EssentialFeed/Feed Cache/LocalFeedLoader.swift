//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-02-12.
//

import Foundation

public class LocalFeedLoader {
    let store: FeedStore
    let timestamp: () -> Date
    
    public typealias SaveResult = Error?
    public typealias LoadResult = LoadFeedResult
    
    public init(store: FeedStore, timestamp: @escaping () -> Date) {
        self.store = store
        self.timestamp = timestamp
    }
    
    public func save(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] cacheDeletionError in
            guard let self else { return }
            guard cacheDeletionError == nil else {
                completion(cacheDeletionError)
                return
            }
            cache(feed, completion: completion)
        }
    }
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve{ error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.success([]))
            }
        }
    }
    
    private func cache(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.saveCacheFeed(feed.toLocal(), timestamp: timestamp()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

public extension Array where Element == FeedImage {
    func toLocal() -> [LocalFeedImage] {
        map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}
