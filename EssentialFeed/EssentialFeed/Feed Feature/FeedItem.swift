//
//  FeedItem.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-01-14.
//

import Foundation

public struct FeedItem: Equatable {
    let id: UUID
    let description: String?
    let location: String?
    let imageURL: String
}
