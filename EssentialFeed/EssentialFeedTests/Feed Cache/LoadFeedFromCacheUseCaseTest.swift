//
//  LoadFeedFromCacheUseCaseTest.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-02-14.
//

import XCTest
import EssentialFeed

final class LoadFeedFromCacheUseCaseTest: XCTestCase {
    
    func test_init_doesNotSendMessagesUpOnCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_load_requestCacheRetrieval() {
        let (sut, store) = makeSUT()
        
        sut.load() { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.retrival])
    }
    
    func test_load_receviedErrorWhenRetrievalFailure() {
        let (sut, store) = makeSUT()
        let expectedError = anyError()
        
        var retrivalError: Error?
        let exp = expectation(description: "Wait for retrieval to complete")
        
        sut.load() { result in
            switch result {
            case .failure(let error):
                retrivalError = error
            default:
                XCTFail("Expected failure but received \(result) instead")
            }
            exp.fulfill()
        }
        
        store.completeRetrivalWithError(error: expectedError)
        wait(for: [exp], timeout: 1.0)
        XCTAssertEqual(retrivalError as? NSError, expectedError)
        
    }
    
    func test_load_retrivalCompletWithNoImagesWhenCacheIsEmpty() {
        let (sut, store) = makeSUT()
        
        let exp = expectation(description: "Wait for retrieval to complete")
        
        sut.load() { result in
            switch result {
            case .success(let feed):
                XCTAssertEqual(feed, [])
            default:
                XCTFail("Expected failure but received \(result) instead")
            }
            exp.fulfill()
        }
        
        store.completeRetrivalWithSuccess()
        wait(for: [exp], timeout: 1.0)
    }
    
    //MARK: Helpers
    
    private func makeSUT(timestamp: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, timestamp: timestamp)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func anyError() -> NSError {
        NSError(domain: "Testing", code: 0)
    }
}
