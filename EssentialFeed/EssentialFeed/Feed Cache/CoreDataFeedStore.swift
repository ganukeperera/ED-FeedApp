//
//  CoreDataFeedStore.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-03-06.
//

import CoreData

public class CoreDataFeedStore: FeedStore {
    let container: NSPersistentContainer
    public init(bundle: Bundle = .main) throws {
        container = try NSPersistentContainer.load(modelName: "FeedStore", in: bundle)
    }
    
    public func retrieve(completion: @escaping RetrivalCompletion) {
        completion(.empty)
    }
    
    public func saveCacheFeed(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        
    }
    
    public func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        
    }
    
}

private extension NSPersistentContainer {
    
    enum LoadError: Error {
        case modelNotFound
        case failedToLoadPersistentStores(Swift.Error)
    }
    
    static func load(modelName name: String, in bundle: Bundle) throws -> NSPersistentContainer {
        guard let model = NSManagedObjectModel.with(name: name, bundle: bundle) else {
            throw LoadError.modelNotFound
        }
        
        let container = NSPersistentContainer(name: name, managedObjectModel: model)
        var error: Error?
        container.loadPersistentStores { error = $1 }
        try error.map { throw LoadError.failedToLoadPersistentStores($0) }
        
        return container
    }
}

private extension NSManagedObjectModel {
    
    static func with(name: String, bundle: Bundle) -> NSManagedObjectModel? {
        return bundle.url(forResource: name, withExtension: "momd").flatMap { NSManagedObjectModel(contentsOf: $0)}
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
