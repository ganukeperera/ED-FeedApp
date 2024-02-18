//
//  LocalFeedLoader.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-02-12.
//

import Foundation

public class LocalFeedLoader {
    private let store: FeedStore
    private let timestamp: () -> Date
    private let calendar = Calendar(identifier: .gregorian)
    
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
        store.retrieve{[weak self] error in
            guard let self else { return }
            switch error {
            case .failure(let error):
                completion(.failure(error))
            case let .success(feed, timestampOfFeed) where self.validateTime(timestampOfFeed):
                completion(.success(feed.toModels()))
            case .success:
                store.deleteCachedFeed { _ in }
                completion(.success([]))
            case .empty:
                completion(.success([]))
            }
        }
    }
    
    public func validateCache() {
        store.retrieve { [unowned self] result in
            switch result {
            case .failure:
                store.deleteCachedFeed { _ in }
            default: break
            }
        }
    }
    
    private var maxAllowedCacheAgeInDays: Int {
        return 7
    }
    
    private func validateTime(_ time: Date) -> Bool {
        guard let maxCacheDate = calendar.date(byAdding: .day, value: maxAllowedCacheAgeInDays, to: time) else {
            return false
        }
        return timestamp() < maxCacheDate
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

public extension Array where Element == LocalFeedImage {
    func toModels() -> [FeedImage] {
        map { FeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url)}
    }
}
