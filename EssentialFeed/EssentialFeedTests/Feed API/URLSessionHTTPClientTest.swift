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
    
    init(session: URLSession = .shared) {
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
    
    func test_getFromURL_completWithAnError() {
        URLProtocolStub.registerForIntercepting()
        let url = URL(string: "https://a-given-url.com")!
        let expectedError = NSError(domain: "Testing", code: 0)
        URLProtocolStub.stub(url: url, error: expectedError)
        let sut = URLSessionHTTPClient()
        
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
        URLProtocolStub.unregisterForIntercepting()
    }
    
    class URLProtocolStub: URLProtocol {
        private static var stubs = [URL: Stub]()
        
        private struct Stub {
            let error: Error?
        }
        
        static func registerForIntercepting() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func unregisterForIntercepting() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
        }
        
        static func stub(url: URL, error: Error? = nil) {
            stubs[url] = Stub(error: error)
        }
        
        class override func canInit(with request: URLRequest) -> Bool {
            guard let url = request.url else { return false }
            
            return stubs[url] != nil
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let url = request.url, let stub = URLProtocolStub.stubs[url] else { return }
            
            if let error = stub.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
