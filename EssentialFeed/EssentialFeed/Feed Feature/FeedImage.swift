//
//  FeedImage.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-01-14.
//

import Foundation

public struct FeedImage: Equatable {
    public let id: UUID
    public let description: String?
    public let location: String?
    public let url: String
    
    public init(id: UUID, description: String?, location: String?, url: String) {
        self.id = id
        self.description = description
        self.location = location
        self.url = url
    }
}
