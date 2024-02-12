//
//  LocalFeedItem.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-02-13.
//

import Foundation

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
