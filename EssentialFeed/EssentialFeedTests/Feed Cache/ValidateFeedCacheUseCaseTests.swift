//
//  ValidateFeedCacheUseCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-02-19.
//
import XCTest
import EssentialFeed

class ValidateFeedCacheUseCaseTests: XCTestCase {
    
    func test_init_doesNotSendMessagesUpOnCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_validateCache_deleteCacheOnRetrievalError() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrivalWithError(error: anyError())
        
        XCTAssertEqual(store.receivedMessages, [.retrival, .deleteMessage])
    }
    
    func test_validateCache_doesNotDeleteCacheWhenCacheIsAlreadyEmpty() {
        let (sut, store) = makeSUT()
        
        sut.validateCache()
        store.completeRetrivalWithEmpty()
        
        XCTAssertEqual(store.receivedMessages, [.retrival])
    }
    
    func test_validateCache_doesNotDeleteCacheOnNonExpiredCache() {
        let fixedDate = Date()
        let nonExpiredTimestamp = fixedDate.minusFeedCacheMaxAge().addSeconds(seconds: 1)
        let (sut, store) = makeSUT{ fixedDate }
        
        sut.validateCache()
        store.completeRetrival(with: uniqueImageFeed().local, timestamp: nonExpiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrival])
    }
    
    func test_validateCache_deleteCacheOnCacheExpiration() {
        let fixedDate = Date()
        let onExpirationTimestamp = fixedDate.minusFeedCacheMaxAge()
        let (sut, store) = makeSUT{ fixedDate }
        
        sut.validateCache()
        store.completeRetrival(with: uniqueImageFeed().local, timestamp: onExpirationTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrival, .deleteMessage])
    }
    
    func test_validateCache_deleteCacheWhenCacheIsAlreadyExpired() {
        let fixedDate = Date()
        let expiredTimestamp = fixedDate.minusFeedCacheMaxAge().addSeconds(seconds: -1)
        let (sut, store) = makeSUT{ fixedDate }
        
        sut.validateCache()
        store.completeRetrival(with: uniqueImageFeed().local, timestamp: expiredTimestamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrival, .deleteMessage])
    }
    
    func test_validateCache_doesNotDeleteCacheWhenTheInstanceIsDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, timestamp: Date.init)
        
        sut?.validateCache()
        sut = nil
        store.completeRetrivalWithError(error: anyError())
        
        XCTAssertEqual(store.receivedMessages, [.retrival])
    }
    
    //MARK: Helpers
    
    private func makeSUT(timestamp: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, timestamp: timestamp)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }

}
