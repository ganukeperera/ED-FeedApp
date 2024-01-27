//
//  URLSessionHTTPClientTest.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-01-27.
//

import Foundation
import XCTest
@testable import EssentialFeed

protocol HTTPSession {
    func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPDataTask
}

protocol HTTPDataTask {
    func resume()
}

class URLSessionHTTPClient {
    let session: HTTPSession
    
    init(session: HTTPSession) {
        self.session = session
    }
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: URLRequest(url: url), completionHandler: {_, _, error in
            guard let error else { return }
            completion(.failure(error))
        }).resume()
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
    
    func test_getFromURL_completWithAnError() {
        let url = URL(string: "https://a-given-url.com")!
        let session = URLSessionSpy()
        let task = URLSessionDataTaskSpy()
        let expectedError = NSError(domain: "Testing", code: 0)
        session.stub(url: url, error: expectedError)
        let sut = URLSessionHTTPClient(session: session)
        
        let expectation = expectation(description: "testing")
        sut.get(from: url, completion: { result in
            switch result {
            case .failure(let error as NSError):
                XCTAssertEqual(error.domain, expectedError.domain)
                XCTAssertEqual(error.code, expectedError.code)
            default:
                XCTFail("expected \(expectedError) but received an success")
            }
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 1.0)
    }
    
    class URLSessionSpy: HTTPSession {
        private var stubs = [URL: (task: HTTPDataTask,error: Error?)]()
        
        func stub(url: URL, dataTask: HTTPDataTask = FakeURLSessionDataTask(), error: Error? = nil) {
            stubs[url] = (task: dataTask, error: error)
        }
        
        func dataTask(with request: URLRequest, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> HTTPDataTask {
            guard let stub = stubs[request.url!] else {
                fatalError("Could not find the task")
            }
            completionHandler(nil, nil, stub.error)
            return stub.task
        }
    }
    
    class FakeURLSessionDataTask: HTTPDataTask {
        func resume() {}
    }
    
    class URLSessionDataTaskSpy: HTTPDataTask {
        var resumeCount = 0
        func resume() {
            resumeCount += 1
        }
    }
}
