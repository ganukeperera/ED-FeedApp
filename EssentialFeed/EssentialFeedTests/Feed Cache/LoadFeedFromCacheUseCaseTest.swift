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
        
        expect(sut, toCompleteWith: .failure(expectedError)) {
            store.completeRetrivalWithError(error: expectedError)
        }
    }
    
    func test_load_retrivalCompletWithNoImagesWhenCacheIsEmpty() {
        let (sut, store) = makeSUT()
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrivalWithSuccess()
        }
    }
    
    //MARK: Helpers
    
    private func makeSUT(timestamp: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, timestamp: timestamp)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, toCompleteWith expectedResult: LocalFeedLoader.LoadResult, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        
        let exp = expectation(description: "Wait for retrieval to complete")
        
        sut.load() { receivedResult in
            switch (expectedResult, receivedResult) {
            case let (.success(expectedImages), .success(receivedImages)):
                XCTAssertEqual(expectedImages, receivedImages, file: file, line: line)
            case let (.failure(expectedError as NSError), .failure(receivedError as NSError)):
                XCTAssertEqual(expectedError, receivedError, file: file, line: line)
            default:
                XCTFail("expected \(expectedResult) but recieved \(receivedResult) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        
        action()
        wait(for: [exp], timeout: 1.0)
    }
    
    private func anyError() -> NSError {
        NSError(domain: "Testing", code: 0)
    }
}
