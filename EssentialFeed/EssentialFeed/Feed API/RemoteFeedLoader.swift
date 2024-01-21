//
//  RemoteFeedLoader.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-01-16.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}

public final class RemoteFeedLoader {
    private let client: HTTPClient
    private let url: URL
    
    public enum Error: Swift.Error {
        case connectivity
        case invalidData
    }
    
    public enum Result: Equatable {
        case success([FeedItem])
        case failure(Error)
    }
    
    public init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    public func load(completion: @escaping (Result) -> Void) {
        client.get(from: url) { result in
            switch result {
            case .success(let data, let response):
                guard response.statusCode == 200, let data = try? JSONDecoder().decode(Root.self, from: data) else {
                    completion(.failure(.invalidData))
                    return
                }
                completion(.success(data.items.map{ $0.item }))
            case .failure:
                completion(.failure(.connectivity))
            }
        }
    }
}
private struct Root: Decodable {
    public let items: [Item]
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
