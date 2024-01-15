//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-01-15.
//

import Foundation
import XCTest

class HTTPClient {
    static let shared = HTTPClient()
    
    var requestedURL: URL?
}

class RemoteFeedLoader {
    
}

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let client = HTTPClient.shared
        let _ = RemoteFeedLoader()
        
        XCTAssertNil(client.requestedURL)
    }
}
