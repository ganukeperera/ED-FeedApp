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
    
    private var maxAllowedCacheAgeInDays: Int {
        return 7
    }
    
    private func validateTime(_ time: Date) -> Bool {
        guard let maxCacheDate = calendar.date(byAdding: .day, value: maxAllowedCacheAgeInDays, to: time) else {
            return false
        }
        return timestamp() < maxCacheDate
    }
}

extension LocalFeedLoader: FeedLoader {
    
    public func load(completion: @escaping (LoadResult) -> Void) {
        store.retrieve{[weak self] error in
            guard let self else { return }
            switch error {
            case .failure(let error):
                completion(.failure(error))
            case let .success(feed, timestampOfFeed) where self.validateTime(timestampOfFeed):
                completion(.success(feed.toModels()))
            case .empty, .success:
                completion(.success([]))
            }
        }
    }
}

extension LocalFeedLoader {
    
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
    
    private func cache(_ feed: [FeedImage], completion: @escaping (SaveResult) -> Void) {
        store.saveCacheFeed(feed.toLocal(), timestamp: timestamp()) { [weak self] error in
            guard self != nil else { return }
            completion(error)
        }
    }
}

extension LocalFeedLoader {
    
    public func validateCache() {
        store.retrieve { [weak self] result in
            guard let self else { return }
            switch result {
            case .failure:
                store.deleteCachedFeed { _ in }
            case let .success(_, timestampOfFeed) where !self.validateTime(timestampOfFeed):
                store.deleteCachedFeed { _ in }
            case .empty, .success:
                break
            }
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
