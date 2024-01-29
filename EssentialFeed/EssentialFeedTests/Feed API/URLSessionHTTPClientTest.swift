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
    
    private struct UnexpectedValueRepresentation: Error {}
    
    func get(from url: URL, completion: @escaping (HTTPClientResult) -> Void) {
        session.dataTask(with: URLRequest(url: url), completionHandler: {_, _, error in
            if let error {
                completion(.failure(error))
            } else {
                completion(.failure(UnexpectedValueRepresentation()))
            }
            
        }).resume()
    }
}

class URLSessionHTTPClientTest: XCTestCase {
    
    override func setUp() {
        super.setUp()
        URLProtocolStub.registerForIntercepting()
    }
    
    override func tearDown() {
        super.tearDown()
        URLProtocolStub.unregisterForIntercepting()
    }
    
    func test_getFromURL_performGETRequestFromURL() {
        let url = anyURL()
        
        makeSUT().get(from: anyURL()) { _ in }
        
        let expectation = expectation(description: "waiting for the test")
        URLProtocolStub.observeRequests { request in
            XCTAssertEqual(request.url, url)
            XCTAssertEqual(request.httpMethod, "GET")
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    func test_getFromURL_completWithAnError() {
        let expectedError = anyError()
        URLProtocolStub.stub(data: nil, response: nil, error: expectedError)
        
        let expectation = expectation(description: "testing")
        makeSUT().get(from: anyURL(), completion: { result in
            switch result {
            case .failure(let error as NSError):
                XCTAssertEqual(error.domain, expectedError.domain)
                XCTAssertEqual(error.code, expectedError.code)
            default:
                XCTFail("expected \(expectedError) but received an success")
            }
            expectation.fulfill()
        })
        wait(for: [expectation], timeout: 3.0)
    }
    
    func test_getFromUrl_completeWithErrorWhenAllValuesAreNil() {
        let sut = makeSUT()
        URLProtocolStub.stub(data: nil, response: nil, error: nil)
        
        let expectation = expectation(description: "wait for the test")
        sut.get(from: anyURL()) { result in
            switch result {
            case .failure:
                break
            default:
                XCTFail("expected failure but received \(result)")
            }
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func anyURL() -> URL {
        URL(string: "https://a-given-url.com")!
    }
    
    private func anyError() -> NSError {
        NSError(domain: "Testing", code: 0)
    }
    
    class URLProtocolStub: URLProtocol {
        private static var stub: Stub?
        private static var observer: ((URLRequest) -> Void)?
        
        private struct Stub {
            let data: Data?
            let response: URLResponse?
            let error: Error?
        }
        
        static func registerForIntercepting() {
            URLProtocol.registerClass(URLProtocolStub.self)
        }
        
        static func unregisterForIntercepting() {
            URLProtocol.unregisterClass(URLProtocolStub.self)
            stub = nil
        }
        
        static func observeRequests(observer: @escaping (URLRequest) -> Void ) {
            URLProtocolStub.observer = observer
        }
        
        static func stub(data: Data?, response: URLResponse?, error: Error?) {
            stub = Stub(data: data, response: response, error: error)
        }
        
        class override func canInit(with request: URLRequest) -> Bool {
            observer?(request)
            return true
        }
        
        override class func canonicalRequest(for request: URLRequest) -> URLRequest {
            return request
        }
        
        override func startLoading() {
            guard let url = request.url else { return }
            
            if let error = URLProtocolStub.stub?.error {
                client?.urlProtocol(self, didFailWithError: error)
            }
            
            if let data = URLProtocolStub.stub?.data {
                client?.urlProtocol(self, didLoad: data)
            }
            
            if let response = URLProtocolStub.stub?.response {
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            }
            client?.urlProtocolDidFinishLoading(self)
        }
        
        override func stopLoading() {}
    }
}
