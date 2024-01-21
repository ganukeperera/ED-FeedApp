//
//  RemoteFeedLoaderTests.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-01-15.
//

import Foundation
import XCTest
import EssentialFeed

class RemoteFeedLoaderTests: XCTestCase {
    
    func test_init_doesNotRequestDataFromURL() {
        let (client, _) = makeSUT()
        
        XCTAssertTrue(client.requestedURLs.isEmpty)
    }
    
    func test_load_requestsDataFromURL() {
        let url = URL(string: "https://a-given-url.com")!
        let (client, sut) = makeSUT(url: url)
        
        sut.load{_ in }
        
        XCTAssertEqual(client.requestedURLs, [url])
    }
    
    func test_loadTwice_requestsDataFromURLTwice() {
        let url = URL(string: "https://a-given-url.com")!
        let (client, sut) = makeSUT(url: url)
        
        sut.load{_ in }
        sut.load{_ in }
        
        XCTAssertEqual(client.requestedURLs.count, 2)
        XCTAssertEqual(client.requestedURLs, [url, url])
    }
    
    func test_loadWithError_deliverAnErrorOnClientCall() {
        let (client, sut) = makeSUT()
        
        expect(sut: sut, error: .connectivity) {
            let error =  NSError(domain: "Test", code: 0)
            client.complete(with: error)
        }
    }
    
    func test_load_deliversAnErrorOnNon200HTTPResponse() {
        let (client, sut) = makeSUT()
        
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, value in
            expect(sut: sut, error: .invalidData) {
                client.complete(withStatusCode: value, index: index)
            }
        }
    }
    
    func test_load_deliversAnErrorWith200HTTPResponseWithInvalidJSON() {
        let (client, sut) = makeSUT()
        
        expect(sut: sut, error: .invalidData) {
            let jsonData = Data("Inavalid JSON".utf8)
            client.complete(withStatusCode: 200, with: jsonData)
        }
    }
    
    //MARK: Helpers
    
    private func expect(sut: RemoteFeedLoader, error: RemoteFeedLoader.Error, action: ()->Void, file: StaticString = #file, line: UInt = #line) {
        var caputuredResult = [RemoteFeedLoader.Result]()
        
        sut.load{caputuredResult.append($0)}
        action()
        XCTAssertEqual(caputuredResult, [.failure(error)], file: file, line: line)
    }
    
    private func makeSUT(url: URL = URL(string: "https://a-url-url.com")!) -> (client: HTTPClientSpy, sut: RemoteFeedLoader){
        let client = HTTPClientSpy()
        let sut = RemoteFeedLoader(url: url, client: client)
        return (client, sut)
    }
    
    private class HTTPClientSpy: HTTPClient {
        var requestedURLs: [URL] {
            messages.map{ $0.url }
        }
        var messages = [(url: URL, completion: (HTTPClientResult) -> Void)]()
        
        func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
            messages.append((url, completion))
        }
        
        func complete(with error: Error, index: Int = 0) {
            messages[index].completion(.failure(error))
        }
        
        func complete(withStatusCode code: Int, with data: Data = Data(), index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}
