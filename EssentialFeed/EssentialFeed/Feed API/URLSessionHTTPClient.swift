//
//  URLSessionHTTPClient.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-01-31.
//

import Foundation

public class URLSessionHTTPClient: HTTPClient {
    private let session: URLSession
    
    public init(session: URLSession = .shared) {
        self.session = session
    }
    
    private struct UnexpectedValueRepresentation: Error {}
    
    public func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: URLRequest(url: url), completionHandler: {data, response, error in
            if let error {
                completion(.failure(error))
                
            } else if let data, let httpResponse = response as? HTTPURLResponse {
                completion(.success(data, httpResponse))
            } else {
                completion(.failure(UnexpectedValueRepresentation()))
            }
            
        }).resume()
    }
}
