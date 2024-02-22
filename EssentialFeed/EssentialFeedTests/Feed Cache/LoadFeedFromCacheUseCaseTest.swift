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
            store.completeRetrivalWithEmpty()
        }
    }
    
    func test_load_deliversCacheImagesOnNonExpiredCache() {
        let fixedDate = Date()
        let nonExpiredTimeStamp = fixedDate.minusFeedCacheMaxAge().addSeconds(seconds: 1)
        let (sut, store) = makeSUT(timestamp: { fixedDate })
        let expectedFeed = uniqueImageFeed()
        
        expect(sut, toCompleteWith: .success(expectedFeed.models)) {
            store.completeRetrival(with: expectedFeed.local, timestamp: nonExpiredTimeStamp)
        }
    }
    
    func test_load_deliversNoImagesOnCacheExpiration() {
        let fixedDate = Date()
        let onExpirationDate = fixedDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT(timestamp: { fixedDate })
        let expectedFeed = uniqueImageFeed()
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrival(with: expectedFeed.local, timestamp: onExpirationDate)
        }
    }
    
    func test_load_deliversNoCacheImagesOnExpiredCache() {
        let fixedDate = Date()
        let expiredTimestamp = fixedDate.minusFeedCacheMaxAge().addSeconds(seconds: -1)
        let (sut, store) = makeSUT(timestamp: { fixedDate })
        let expectedFeed = uniqueImageFeed()
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrival(with: expectedFeed.local, timestamp: expiredTimestamp)
        }
    }
    
    func test_load_noSideEffectOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrivalWithError(error: anyError())
        
        XCTAssertEqual(store.receivedMessages, [.retrival])
    }
    
    func test_load_noSideEffectWhenCacheIsAlreadyEmpty() {
        let (sut, store) = makeSUT()
        
        sut.load { _ in }
        store.completeRetrivalWithEmpty()
        
        XCTAssertEqual(store.receivedMessages, [.retrival])
    }
    
    func test_load_noSideEffectsWhenCacheIsNotExpired() {
        let fixedDate = Date()
        let nonExpiredTimestamp = fixedDate.minusFeedCacheMaxAge().addSeconds(seconds: 1)
        let (sut, store) = makeSUT{ fixedDate }
        
        sut.load { _ in }
        store.completeRetrival(with: uniqueImageFeed().local, timestamp: nonExpiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrival])
    }
    
    func test_load_hasNoSideEffectsOnCacheExpiration() {
        let fixedDate = Date()
        let onExpirationTimestamp = fixedDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT{ fixedDate }
        
        sut.load { _ in }
        store.completeRetrival(with: uniqueImageFeed().local, timestamp: onExpirationTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrival])
    }
    
    func test_load_hasNoSideEffectsWhenCacheIsExpired() {
        let fixedDate = Date()
        let expiredTimeStamp = fixedDate.minusFeedCacheMaxAge().addSeconds(seconds: -1)
        let (sut, store) = makeSUT{ fixedDate }
        
        sut.load { _ in }
        store.completeRetrival(with: uniqueImageFeed().local, timestamp: expiredTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrival])
    }
    
    func test_load_doesNotDeliverMessagesWhenTheInstancesDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, timestamp: Date.init)
        var receivedMessages = [LocalFeedLoader.LoadResult]()
        
        sut?.load { result in
            receivedMessages.append(result)
        }
        sut = nil
        store.completeRetrivalWithEmpty()
        
        XCTAssertTrue(receivedMessages.isEmpty)
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
}
