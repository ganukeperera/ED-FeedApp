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
    
    public init(store: FeedStore, timestamp: @escaping () -> Date) {
        self.store = store
        self.timestamp = timestamp
    }
    
    public func save(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.deleteCachedFeed { [weak self] cacheDeletionError in
            guard let self else { return }
            guard cacheDeletionError == nil else {
                completion(cacheDeletionError)
                return
            }
            cache(items, completion: completion)
        }
    }
    
    private func cache(_ items: [FeedItem], completion: @escaping (SaveResult) -> Void) {
        store.saveCacheFeed(items: items.toLocal(), timestamp: timestamp()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

public extension Array where Element == FeedItem {
    func toLocal() -> [LocalFeedItem] {
        map { LocalFeedItem(id: $0.id, description: $0.description, location: $0.location, imageURL: $0.imageURL)}
    }
}
