//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-01-27.
//

import Foundation
import XCTest
@testable import EssentialFeed

class URLSessionHTTPClient {
    let session: URLSession
    
    init(session: URLSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: URLRequest(url: url), completionHandler: {_, _, _ in})
    }
}

class URLSessionHTTPClientTest: XCTestCase {
    
    func test_getFromURL_createsADataTaskWithURL() {
        let url = URL(string: "https://a-url-session.com")!
        let session = URLSessionSpy()
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url, completion: {_ in})
        
        XCTAssertEqual(session.receivedURLs, [url])
    }
    
    class URLSessionSpy: URLSession {
        var receivedURLs = [URL]()
        
        override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            receivedURLs.append(request.url!)
            return FakeURLSessionDataTask()
        }
    }
    
    class FakeURLSessionDataTask: URLSessionDataTask {}
}
