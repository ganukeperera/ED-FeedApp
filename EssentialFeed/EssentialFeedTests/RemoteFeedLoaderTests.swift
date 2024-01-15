//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-01-15.
//

import Foundation
import XCTest

protocol HTTPClient {
    func get(from url: URL)
}

class RemoteFeedLoader {
    let client: HTTPClient
    let url: URL
    
    init(url: URL, client: HTTPClient) {
        self.client = client
        self.url = url
    }
    
    func load(){
        client.get(from: url)
    }
}

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (client, _) = makeSUT()
        
        XCTAssertNil(client.requestedURL)
    }
    
    func test_load_requestDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (client, sut) = makeSUT(url: url)
        
        sut.load()
        
        XCTAssertEqual(client.requestedURL, url)
    }
    
    //MARK: Helpers
    private func makeSUT(url: URL = URL(string: "https://a-url-url.com")!) -> (client: HTTPClientSpy, sut: RemoteFeedLoader){
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (client, sut)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURL: URL?
        
        func get(from url: URL) {
            self.requestedURL = url
        }
    }
}
