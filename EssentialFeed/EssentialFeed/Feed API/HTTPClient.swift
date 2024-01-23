//
//  HTTPClient.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-01-24.
//

import Foundation

public enum HTTPClientResult {
    case success(Data, HTTPURLResponse)
    case failure(Error)
}

public protocol HTTPClient {
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void)
}
