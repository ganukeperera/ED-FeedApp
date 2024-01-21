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
        
        expect(sut: sut, result: .failure(.connectivity)) {
            let error =  NSError(domain: "Test", code: 0)
            client.complete(with: error)
        }
    }
    
    func test_load_deliversAnErrorOnNon200HTTPResponse() {
        let (client, sut) = makeSUT()
        
        let jsonData = makeJsonData(from: [])
        let samples = [199, 201, 300, 400, 500]
        samples.enumerated().forEach { index, value in
            expect(sut: sut, result: .failure(.invalidData)) {
                client.complete(withStatusCode: value, with: jsonData, index: index)
            }
        }
    }
    
    func test_load_deliversAnErrorWith200HTTPResponseWithInvalidJSON() {
        let (client, sut) = makeSUT()
        
        expect(sut: sut, result: .failure(.invalidData)) {
            let jsonData = Data("Inavalid JSON".utf8)
            client.complete(withStatusCode: 200, with: jsonData)
        }
    }
    
    func test_load_deliversAnEmptyArrayWithHTTP200ResponseWithEmptyJSONData() {
        let (client, sut) = makeSUT()
        
        expect(sut: sut, result: .success([])) {
            let jsonData = makeJsonData(from: [])
            client.complete(withStatusCode: 200, with: jsonData)
        }
    }
    
    func test_load_deliversFeedItemsArrayWithHTTP200ResponseWithValidJSONData() {
        let (client, sut) = makeSUT()
        
        let (model1, item1Json) = makeItems(id: UUID(),
                             description: nil,
                             location: nil,
                             imageURL: "https://a-image-url.com")
        
        let (model2, item2Json) = makeItems(id: UUID(),
                             description: "description",
                             location: "location",
                             imageURL: "https://a-image-url.com")
        
        let jsonData = makeJsonData(from: [item1Json, item2Json])
        
        expect(sut: sut, result: .success([model1, model2])) {
            client.complete(withStatusCode: 200, with: jsonData)
        }
    }
    
    //MARK: Helpers
    private func makeItems(id: UUID, description: String? = nil, location: String? = nil, imageURL: String) -> (model: FeedItem, jsonItem: [String: Any]) {
        let model = FeedItem(id: id,
                             description: description,
                             location: location,
                             imageURL: imageURL)
        
        let itemJson = ["id": model.id.uuidString,
                        "description": model.description,
                        "location": model.location,
                        "image": model.imageURL].compactMapValues{ $0 }
        return (model, itemJson)
    }
    
    private func makeJsonData(from itemsJson: [[String: Any]]) -> Data {
        try! JSONSerialization.data(withJSONObject: ["items" : itemsJson])
    }
    
    private func expect(sut: RemoteFeedLoader, result: RemoteFeedLoader.Result, action: ()->Void, file: StaticString = #file, line: UInt = #line) {
        var caputuredResult = [RemoteFeedLoader.Result]()
        
        sut.load{caputuredResult.append($0)}
        action()
        XCTAssertEqual(caputuredResult, [result], file: file, line: line)
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
        
        func complete(withStatusCode code: Int, with data: Data, index: Int = 0) {
            let response = HTTPURLResponse(url: requestedURLs[index], statusCode: code, httpVersion: nil, headerFields: nil)!
            messages[index].completion(.success(data, response))
        }
    }
}
