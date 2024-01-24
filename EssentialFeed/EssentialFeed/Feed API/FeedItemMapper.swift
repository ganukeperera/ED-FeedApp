//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-01-24.
//

import Foundation

internal final class FeedItemMapper {
    private struct Root: Decodable {
        let items: [Item]
        
        var feedItems: [FeedItem] {
            items.map({ $0.item })
        }
    }

    private struct Item: Decodable {
        let id: UUID
        let description: String?
        let location: String?
        let image: String
        
        var item: FeedItem {
            FeedItem(id: id, description: description, location: location, imageURL: image)
        }
    }
    
    private static var OK_200: Int { return 200 }
    
    internal static func map(_ data: Data, _ response: HTTPURLResponse) -> RemoteFeedLoader.Result {
        
        guard response.statusCode == OK_200, let root =  try? JSONDecoder().decode(Root.self, from: data)  else {
            return .failure(.invalidData)
        }
        
        let items = root.feedItems
        return .success(items)
    }
}
