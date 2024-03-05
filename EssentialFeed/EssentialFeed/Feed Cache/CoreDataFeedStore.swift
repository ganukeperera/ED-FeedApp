//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-03-06.
//

import Foundation

public class CoreDataFeedStore: FeedStore {
    
    public init() {}
    
    public func retrieve(completion: @escaping RetrivalCompletion) {
        completion(.empty)
    }
    
    public func saveCacheFeed(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        
    }
    
}
