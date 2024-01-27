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
        session.dataTask(with: URLRequest(url: url), completionHandler: {_, _, _ in}).resume()
    }
}

class URLSessionHTTPClientTest: XCTestCase {
    
    func test_getFromURL_resumeADataTaskWithURL() {
        let url = URL(string: "https://a-url-session.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        session.stub(url: url, dataTask: task)
        let sut = URLSessionHTTPClient(session: session)
        
        sut.get(from: url, completion: {_ in})
        
        XCTAssertEqual(task.resumeCount, 1)
    }
    
    class URLSessionSpy: URLSession {
        private var stubs = [URL: URLSessionDataTask]()
        
        func stub(url: URL, dataTask: URLSessionDataTask) {
            stubs[url] = dataTask
        }
        
        override func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
            return stubs[request.url!] ?? FakeURLSessionDataTask()
        }
    }
    
    class FakeURLSessionDataTask: URLSessionDataTask {
        override func resume() {
        }
    }
    
    class URLSessionDataTaskSpy: URLSessionDataTask {
        var resumeCount = 0
        override func resume() {
            resumeCount += 1
        }
    }
}
