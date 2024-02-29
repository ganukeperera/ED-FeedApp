//
//  CodableFeedStore.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-02-28.
//

import Foundation

public class CodableFeedStore: FeedStore {
    private struct Cache: Codable {
        let feed: [CodableFeedImage]
        let timestamp: Date
    }
    
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: String
        
        init(_ localFeedImage: LocalFeedImage) {
            id = localFeedImage.id
            description = localFeedImage.description
            location = localFeedImage.location
            url = localFeedImage.url
        }
        
        var localFeed: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL: URL
    
    public init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    public func saveCacheFeed(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let codableLocalFeed = feed.map { CodableFeedImage($0)}
        let cache = Cache(feed: codableLocalFeed, timestamp: timestamp)
        do {
            let encodedObject = try JSONEncoder().encode(cache)
            try encodedObject.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    public func retrieve(completion: @escaping RetrivalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }
        do{
            let cache = try JSONDecoder().decode(Cache.self, from: data)
            let feed = cache.feed.map { $0.localFeed }
            completion(.success(feed: feed, timeStamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: storeURL.path) else { return completion(nil) }
        do {
            try fileManager.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}
