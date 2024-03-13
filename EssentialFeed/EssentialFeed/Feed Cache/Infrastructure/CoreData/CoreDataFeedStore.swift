//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-03-06.
//

import CoreData

public final class CoreDataFeedStore: FeedStore {
    private let container: NSPersistentContainer
    private let context: NSManagedObjectContext
    private let storeName = "FeedStore"
    
    public init(storeURL: URL, bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(modelName: storeName, url: storeURL, in: bundle)
        context = container.newBackgroundContext()
    }
    
    public func retrieve(completion: @escaping RetrivalCompletion) {
        performAsync { context in
            do {
                if let cache = try ManagedCache.find(in: context) {
                    completion(.success(feed: cache.localFeed, timeStamp: cache.timestamp))
                } else {
                    completion(.empty)
                }
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    public func saveCacheFeed(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        performSync { context in
            do {
                let managedCache = try ManagedCache.newUniqueInstance(in: context)
                managedCache.timestamp = timestamp
                managedCache.feed = ManagedFeedImage.images(from: feed, in: context)

                try context.save()
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        performSync { context in
            do {
                try ManagedCache.find(in: context).map(context.delete).map(context.save)
                completion(nil)
            } catch {
                completion(error)
            }
        }
    }
    
    private func performSync(action: @escaping (_ context: NSManagedObjectContext) -> Void) {
        let context = context
        context.performAndWait {
            action(context)
        }
    }
    
    private func performAsync(action: @escaping (_ context: NSManagedObjectContext) -> Void) {
        let context = context
        context.perform {
            action(context)
        }
    }
}

