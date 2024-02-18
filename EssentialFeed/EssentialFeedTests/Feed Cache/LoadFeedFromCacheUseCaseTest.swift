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
    
    func test_load_deliversCacheImagesOnLessThanSevenDaysOldCache() {
        let fixedDate = Date()
        let lessthanSevenDaysTimeStamp = fixedDate.addDate(days: -7).addSeconds(seconds: 1)
        let (sut, store) = makeSUT(timestamp: { fixedDate })
        let expectedFeed = uniqueImageFeed()
        
        expect(sut, toCompleteWith: .success(expectedFeed.models)) {
            store.completeRetrival(with: expectedFeed.local, timestamp: lessthanSevenDaysTimeStamp)
        }
    }
    
    func test_load_deliversNoImagesOnSevenDaysOldCache() {
        let fixedDate = Date()
        let sevenDaysTimeStamp = fixedDate.addDate(days: -7)
        let (sut, store) = makeSUT(timestamp: { fixedDate })
        let expectedFeed = uniqueImageFeed()
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrival(with: expectedFeed.local, timestamp: sevenDaysTimeStamp)
        }
    }
    
    func test_load_deliversNoCacheImagesOnMoreThanSevenDaysOldCache() {
        let fixedDate = Date()
        let morethanSevenDaysTimeStamp = fixedDate.addDate(days: -7).addSeconds(seconds: -1)
        let (sut, store) = makeSUT(timestamp: { fixedDate })
        let expectedFeed = uniqueImageFeed()
        
        expect(sut, toCompleteWith: .success([])) {
            store.completeRetrival(with: expectedFeed.local, timestamp: morethanSevenDaysTimeStamp)
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
    
    func test_load_doesNotDeleteCacheWhenCacheIsLessThanSevenDaysOld() {
        let fixedDate = Date()
        let lessThanSevenDaysTimeStamp = fixedDate.addDate(days: -7).addSeconds(seconds: 1)
        let (sut, store) = makeSUT{ fixedDate }
        
        sut.load { _ in }
        store.completeRetrival(with: uniqueImageFeed().local, timestamp: lessThanSevenDaysTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrival])
    }
    
    func test_load_deleteCacheWhenCacheIsSevenDaysOld() {
        let fixedDate = Date()
        let lessThanSevenDaysTimeStamp = fixedDate.addDate(days: -7)
        let (sut, store) = makeSUT{ fixedDate }
        
        sut.load { _ in }
        store.completeRetrival(with: uniqueImageFeed().local, timestamp: lessThanSevenDaysTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrival, .deleteMessage])
    }
    
    func test_load_deleteCacheWhenCacheIsMoreThanSevenDaysOld() {
        let fixedDate = Date()
        let lessThanSevenDaysTimeStamp = fixedDate.addDate(days: -7).addSeconds(seconds: -1)
        let (sut, store) = makeSUT{ fixedDate }
        
        sut.load { _ in }
        store.completeRetrival(with: uniqueImageFeed().local, timestamp: lessThanSevenDaysTimeStamp)
        
        XCTAssertEqual(store.receivedMessages, [.retrival, .deleteMessage])
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
    
    private func uniqueImage() -> FeedImage {
        FeedImage(id: UUID(), description: "any description", location: "anyLocation", url: anyURL())
    }
    
    private func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
        let feed = [uniqueImage(), uniqueImage()]
        let localItems = feed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
        return (feed, localItems)
    }
    
    private func anyURL() -> String {
        "https://a-given-url.com"
    }
    
    private func anyError() -> NSError {
        NSError(domain: "Testing", code: 0)
    }
}

extension Date {
    func addDate(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func addSeconds(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
