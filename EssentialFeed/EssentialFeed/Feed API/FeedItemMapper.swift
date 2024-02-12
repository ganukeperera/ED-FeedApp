//
//  FeedItemMapper.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-01-24.
//

import Foundation

enum FeedItemMapper {
    
    private static var OK_200: Int { return 200 }
    
    static func map(_ data: Data, _ response: HTTPURLResponse) throws -> [RemoteFeedItem] {
        
        guard response.statusCode == OK_200, let root =  try? JSONDecoder().decode(Root.self, from: data)  else {
            throw RemoteFeedLoader.Error.invalidData
        }

        return root.items
    }
}

extension FeedItemMapper {
    private struct Root: Decodable {
        let items: [RemoteFeedItem]
    }
}
