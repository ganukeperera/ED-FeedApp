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
    
    func test_validateCache_doesNotDeleteCacheWhenCacheIsLessThanSevenDaysOld() {
        let fixedDate = Date()
        let lessThanSevenDaysTimeStamp = fixedDate.addDate(days: -7).addSeconds(seconds: 1)
        let (sut, store) = makeSUT{ fixedDate }
        
        sut.validateCache()
        store.completeRetrival(with: uniqueImageFeed().local, timestamp: lessThanSevenDaysTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrival])
    }
    
    func test_validateCache_deleteCacheWhenCacheIsSevenDaysOld() {
        let fixedDate = Date()
        let lessThanSevenDaysTimeStamp = fixedDate.addDate(days: -7)
        let (sut, store) = makeSUT{ fixedDate }
        
        sut.validateCache()
        store.completeRetrival(with: uniqueImageFeed().local, timestamp: lessThanSevenDaysTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrival, .deleteMessage])
    }
    
    func test_validateCache_deleteCacheWhenCacheIsMoreThanSevenDaysOld() {
        let fixedDate = Date()
        let lessThanSevenDaysTimeStamp = fixedDate.addDate(days: -7).addSeconds(seconds: -1)
        let (sut, store) = makeSUT{ fixedDate }
        
        sut.validateCache()
        store.completeRetrival(with: uniqueImageFeed().local, timestamp: lessThanSevenDaysTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrival, .deleteMessage])
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
