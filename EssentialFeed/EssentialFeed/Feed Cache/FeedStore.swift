//
//  FeedStore.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-02-12.
//

import Foundation

public protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func saveCacheFeed(items: [LocalFeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}

public struct LocalFeedItem: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let imageURL: String
    
    public init(id: UUID, description: String?, location: String?, imageURL: String) {
        self.id = id
        self.description = description
        self.location = location
        self.imageURL = imageURL
    }
}
