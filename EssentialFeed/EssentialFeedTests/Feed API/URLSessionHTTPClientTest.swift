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
        session.dataTask(with: URLRequest(url: url), completionHandler: {data, response, error in
            if let error {
                completion(.failure(error))
                
            } else if let data, let httpResponse = response as? HTTPURLResponse {
                completion(.success(data, httpResponse))
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
        let resultedError = resultErrorFor(data: nil, response: nil, error: expectedError)
        XCTAssertEqual((resultedError as? NSError)?.domain, expectedError.domain)
        XCTAssertEqual((resultedError as? NSError)?.code, expectedError.code)
    }
    
    func test_getFromUrl_failsOnAllInvalidRepresentationCases() {
        XCTAssertNotNil(resultErrorFor(data: nil, response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: nil))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nil, error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: nonHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: nil, response: anyHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: anyHTTPURLResponse(), error: anyError()))
        XCTAssertNotNil(resultErrorFor(data: anyData(), response: nonHTTPURLResponse(), error: nil))
    }
    
    func test_getFromUrl_succeedWithHTTPURLResponseAndData() {
        let expectedData = anyData()
        let expectedResponse = anyHTTPURLResponse()
        
        let result = resultResponseFor(data: expectedData, response: expectedResponse, error: nil)
        
        XCTAssertEqual(expectedData, result?.data)
        XCTAssertEqual(expectedResponse.url, result?.response.url)
        XCTAssertEqual(expectedResponse.statusCode, result?.response.statusCode)
    }
    
    func test_getFromUrl_succeedWithHTTPURLResponseAndNilData() {
        let expectedResponse = anyHTTPURLResponse()
        
        let result = resultResponseFor(data: nil, response: expectedResponse, error: nil)
        
        let emptyData = Data()
        XCTAssertEqual(result?.data, emptyData)
        XCTAssertEqual(expectedResponse.url, result?.response.url)
        XCTAssertEqual(expectedResponse.statusCode, result?.response.statusCode)
    }
    
    // MARK: - Helpers
    
    private func makeSUT(file: StaticString = #file, line: UInt = #line) -> URLSessionHTTPClient {
        let sut = URLSessionHTTPClient()
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func resultResponseFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> (data: Data, response: HTTPURLResponse)? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        switch result {
        case let .success(data, response):
           return (data, response)
        default:
            XCTFail("expected failure but received \(result)", file: file, line: line)
            return nil
        }
    }
    
    private func resultErrorFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> Error? {
        let result = resultFor(data: data, response: response, error: error, file: file, line: line)
        switch result {
        case .failure(let error):
            return error
        default:
            XCTFail("expected failure but received \(result)", file: file, line: line)
            return nil
        }
    }
    
    private func resultFor(data: Data?, response: URLResponse?, error: Error?, file: StaticString = #file, line: UInt = #line) -> HTTPClientResult {
        URLProtocolStub.stub(data: data, response: response, error: error)
        var capturedResult: HTTPClientResult!
        let sut = makeSUT(file: file, line: line)
        let expectation = expectation(description: "wait for the test")
        sut.get(from: anyURL()) { result in
            capturedResult = result
            expectation.fulfill()
        }
        wait(for: [expectation], timeout: 1.0)
        return capturedResult
    }
    
    private func anyHTTPURLResponse() -> HTTPURLResponse {
        HTTPURLResponse(url: anyURL(), statusCode: 200, httpVersion: nil, headerFields: nil)!
    }
    
    private func nonHTTPURLResponse() -> URLResponse {
        URLResponse(url: anyURL(), mimeType: nil, expectedContentLength: 0, textEncodingName: nil)
    }
    
    private func anyData() -> Data {
        Data("any data".utf8)
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
            observer = nil
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
