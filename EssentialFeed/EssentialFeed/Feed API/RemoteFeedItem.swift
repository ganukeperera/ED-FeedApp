//
//  RemoteFeedItem.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-02-13.
//

import Foundation

struct RemoteFeedItem: Decodable {
    let id: UUID
    let description: String?
    let location: String?
    let image: String
}
