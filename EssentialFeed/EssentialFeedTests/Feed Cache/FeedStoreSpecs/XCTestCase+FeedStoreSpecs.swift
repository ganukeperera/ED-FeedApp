//
//  XCTestCase+FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-03-04.
//

import XCTest
import EssentialFeed

extension FeedStoreSpecs where Self: XCTestCase {
    
    func assertThatRetrieveDeliversEmptyOnEmptyCache ( on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatRetrieveHasNoSideEffectOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieveTwice: .empty, file: file, line: line)
    }
    
    func assertThatRetrieveDeliversFoundValuesOnNonEmptyCache (on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed, timestamp: timestamp, to: sut)
        
        expect(sut, toRetrieve: .success(feed: feed, timeStamp: timestamp), file: file, line: line)
    }
    
    func assertThatRetreiveHasNoSideEffectOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed, timestamp: timestamp, to: sut)
        
        expect(sut, toRetrieveTwice: .success(feed: feed, timeStamp: timestamp), file: file, line: line)
    }
    
    func assertThatInsertDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let insertionError = insert(uniqueImageFeed().local, timestamp: Date(), to: sut)
        
        XCTAssertNil(insertionError, "Expect feed to be insert successfuly")
    }
    
    func assertThatInsertDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(uniqueImageFeed().local, timestamp: Date(), to: sut)
        
        let insertionError = insert(uniqueImageFeed().local, timestamp: Date(), to: sut)
        
        XCTAssertNil(insertionError, "Expect feed to be insert successfuly")
    }
    
    func assertThatInsertOveridePreviouslyInsertedCacheValues(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        
        insert(uniqueImageFeed().local, timestamp: Date(), to: sut)
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed, timestamp: timestamp, to: sut)
        
        expect(sut, toRetrieve: .success(feed: feed, timeStamp: timestamp), file: file, line: line)
    }
    
    func assertThatDeleteDeliversNoErrorOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        let deletionError = delete(sut)

        XCTAssertNil(deletionError, "Expected empty cache deletion to succeed")
    }
    
    func assertThatDeleteHasNoSideEffectOnEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        delete(sut)
        
        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatDeleteDeliversNoErrorOnNonEmptyCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(uniqueImageFeed().local, timestamp: Date(), to: sut)

        let deletionError = delete(sut)
        
        XCTAssertNil(deletionError, "Expected no error on deleting non empty cache")
    }
    
    func assertThatDeleteEmptiesPrviouslyInsertedCache(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        insert(uniqueImageFeed().local, timestamp: Date(), to: sut)

        delete(sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
    
    func assertThatStoreSideEffectsRunSerially(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        var compeletionOperationsInOrder = [XCTestExpectation]()
        
        let op1 = expectation(description: "Operation 1")
        sut.saveCacheFeed(uniqueImageFeed().local, timestamp: Date()) { _ in
            compeletionOperationsInOrder.append(op1)
            op1.fulfill()
        }
        
        let op2 = expectation(description: "Operation 2")
        sut.deleteCachedFeed { _ in
            compeletionOperationsInOrder.append(op2)
            op2.fulfill()
        }
        
        let op3 = expectation(description: "Operation 3")
        sut.saveCacheFeed(uniqueImageFeed().local, timestamp: Date()) { _ in
            compeletionOperationsInOrder.append(op3)
            op3.fulfill()
        }
        waitForExpectations(timeout: 5.0)
        
        XCTAssertEqual(compeletionOperationsInOrder, [op1, op2, op3])
    }
    
    @discardableResult
    func delete(_ sut: FeedStore) -> Error? {
        let exp = expectation(description: "wait for deletion on empty cache")
        var deletionError: Error?
        sut.deleteCachedFeed { error in
            deletionError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 2.0)
        return deletionError
    }
    
    @discardableResult
    func insert(_ feed: [LocalFeedImage], timestamp: Date, to sut: FeedStore) -> Error? {
        let exp = expectation(description: "waiting for retrieve to complete")
        var insertionError: Error?
        sut.saveCacheFeed(feed, timestamp: timestamp) { receivedError in
            insertionError = receivedError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        let exp = expectation(description: "waiting for retrieve to complete")
        
        sut.retrieve { result in
            switch (result, expectedResult) {
            case (.empty, .empty), (.failure, .failure):
                break
            case let (.success(foundFeed, foundTimestamp), .success(expectedFeed, expectedTimestamp)):
                XCTAssertEqual(foundFeed, expectedFeed, file: file, line: line)
                XCTAssertEqual(foundTimestamp, expectedTimestamp, file: file, line: line)
            default:
                XCTFail("expected \(expectedResult) but received \(result) instead", file: file, line: line)
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
}
