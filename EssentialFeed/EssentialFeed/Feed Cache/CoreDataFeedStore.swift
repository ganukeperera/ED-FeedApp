//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-03-06.
//

import CoreData

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

private class ManagedCache: NSManagedObject {
    @NSManaged var timestamp: Date
    @NSManaged var feed: NSOrderedSet
}

private class ManagedFeedImage: NSManagedObject {
    @NSManaged var id: UUID
    @NSManaged var location: String?
    @NSManaged var imageDescription: String?
    @NSManaged var url: URL
    @NSManaged var cache: ManagedCache
    
}
