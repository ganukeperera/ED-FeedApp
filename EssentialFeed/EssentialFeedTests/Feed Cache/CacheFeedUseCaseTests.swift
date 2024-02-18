//
//  CacheFeedCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-02-07.
//

import XCTest
import EssentialFeed

final class CacheFeedUseCaseTests: XCTestCase {

    func test_init_doesNotSendMessagesUpOnCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestDeleteWhenRequestSave() {
        let (sut, store) = makeSUT()
        
        sut.save(uniqueImageFeed().models) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteMessage])
    }
    
    func test_save_doesnotCallSaveWhenDeletionFails() {
        let (sut, store) = makeSUT()
        
        sut.save(uniqueImageFeed().models) { _ in }
        store.completeDeletionWithError(error: anyError())
        
        XCTAssertEqual(store.receivedMessages, [.deleteMessage])
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(timestamp: { timestamp })
        let feed = uniqueImageFeed()
        
        sut.save(feed.models) { _ in }
        store.completeDeletionWithSuccess()
        
        XCTAssertEqual(store.receivedMessages, [.deleteMessage, .insertionMeessage(feed.local, timestamp)])
    }
    
    func test_save_deliverAnErrorWhenDeletionFailure() {
        let (sut, store) = makeSUT()
        let expectedError = anyError()
        
        expect(sut, completeWith: expectedError) {
            store.completeDeletionWithError(error: expectedError)
        }
    }
    
    func test_save_deliverAnErrorWhenInsertionFailure() {
        let (sut, store) = makeSUT()
        let expectedError = anyError()
        
        expect(sut, completeWith: expectedError) {
            store.completeDeletionWithSuccess()
            store.completeInsertionWithError(error: expectedError)
        }
    }
    
    func test_save_completeWithSuccessWhenCacheInsertionSuccess() {
        let (sut, store) = makeSUT()
        
        expect(sut, completeWith: nil) {
            store.completeDeletionWithSuccess()
            store.completeInsertionWithSuccess()
        }
    }
    
    func test_save_doesNotReceiveDeletionErrorWhenLocalFeedLoaderIsDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, timestamp: Date.init)
        
        var receivedMessage: LocalFeedLoader.SaveResult = nil
        sut?.save(uniqueImageFeed().models) { error in
            receivedMessage = error
        }
        
        sut = nil
        store.completeDeletionWithError(error: anyError())
        
        XCTAssertNil(receivedMessage)
    }
    
    func test_save_doesNotReceiveInsertionErrorWhenLocalFeedLoaderIsDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, timestamp: Date.init)
        
        var receivedMessage: LocalFeedLoader.SaveResult = nil
        sut?.save(uniqueImageFeed().models) { error in
            receivedMessage = error
        }
        
        store.completeDeletionWithSuccess()
        sut = nil
        store.completeInsertionWithError(error: anyError())
        
        XCTAssertNil(receivedMessage)
    }
    
    //MARK: Helpers
    
    private func makeSUT(timestamp: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, timestamp: timestamp)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private func expect(_ sut: LocalFeedLoader, completeWith expectedError: NSError?, when action: () -> Void, file: StaticString = #filePath, line: UInt = #line) {
        var receivedError: LocalFeedLoader.SaveResult = nil
        
        let expectation = expectation(description: "wait for insertion completion")
        sut.save(uniqueImageFeed().models) { error in
            receivedError = error
            expectation.fulfill()
        }
        action()
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(expectedError, receivedError as? NSError, file: file, line: line)
    }
}
