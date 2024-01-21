//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-01-14.
//

import Foundation

public struct FeedItem: Equatable, Decodable {
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
    
    private enum CodingKeys: String, CodingKey {
        case id
        case description
        case location
        case imageURL = "image"
    }
}
