//
//  CacheFeedCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-02-07.
//

import XCTest
import EssentialFeed

class LocalFeedLoader {
    let store: FeedStore
    let timestamp: () -> Date
    init(store: FeedStore, timestamp: @escaping () -> Date) {
        self.store = store
        self.timestamp = timestamp
    }
    
    func save(_ items: [FeedItem], completion: @escaping (Error?) -> Void) {
        store.deleteCachedFeed { [weak self] error in
            guard let self else { return }
            if error == nil {
                self.store.saveCacheFeed(items: items, timestamp: timestamp()) { [weak self] error in
                    guard self != nil else { return }
                    completion(error)
                }
            } else {
                completion(error)
            }
        }
    }
}

protocol FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    typealias InsertionCompletion = (Error?) -> Void
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion)
    func saveCacheFeed(items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion)
}

final class CacheFeedCaseTests: XCTestCase {

    func test_init_doesNotSendMessagesUpOnCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.receivedMessages, [])
    }
    
    func test_save_requestDeleteWhenRequestSave() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items) { _ in }
        
        XCTAssertEqual(store.receivedMessages, [.deleteMessage])
    }
    
    func test_save_doesnotCallSaveWhenDeletionFails() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items) { _ in }
        store.completeDeletionWithError(error: anyError())
        
        XCTAssertEqual(store.receivedMessages, [.deleteMessage])
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(timestamp: { timestamp })
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items) { _ in }
        store.completeDeletionWithSuccess()
        
        XCTAssertEqual(store.receivedMessages, [.deleteMessage, .insertionMeessage(items, timestamp)])
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
        
        var receivedMessage: Error?
        sut?.save([uniqueItem()]) { error in
            receivedMessage = error
        }
        
        sut = nil
        store.completeDeletionWithError(error: anyError())
        
        XCTAssertNil(receivedMessage)
    }
    
    func test_save_doesNotReceiveInsertionErrorWhenLocalFeedLoaderIsDeallocated() {
        let store = FeedStoreSpy()
        var sut: LocalFeedLoader? = LocalFeedLoader(store: store, timestamp: Date.init)
        
        var receivedMessage: Error?
        sut?.save([uniqueItem()]) { error in
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
        let items = [uniqueItem(), uniqueItem()]
        var receivedError: Error?
        
        let expectation = expectation(description: "wait for insertion completion")
        sut.save(items) { error in
            receivedError = error
            expectation.fulfill()
        }
        action()
        wait(for: [expectation], timeout: 1.0)
        XCTAssertEqual(expectedError, receivedError as? NSError, file: file, line: line)
    }
    
    private class FeedStoreSpy: FeedStore {
        typealias DeletionCompletion = (Error?) -> Void
        typealias InsertionCompletion = (Error?) -> Void
        private(set) var deletionCompletions = [DeletionCompletion]()
        private(set) var insertionCompletions = [InsertionCompletion]()
        private(set) var receivedMessages = [RecievedMessage]()
        
        enum RecievedMessage: Equatable {
            case deleteMessage
            case insertionMeessage([FeedItem], Date)
        }
        
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            receivedMessages.append(.deleteMessage)
            deletionCompletions.append(completion)
        }
        
        func saveCacheFeed(items: [FeedItem], timestamp: Date, completion: @escaping InsertionCompletion) {
            receivedMessages.append(.insertionMeessage(items, timestamp))
            insertionCompletions.append(completion)
        }
        
        func completeDeletionWithError(error: Error, at index: Int = 0) {
            deletionCompletions[index](error)
        }
        
        func completeDeletionWithSuccess(at index: Int = 0) {
            deletionCompletions[index](nil)
        }
        
        func completeInsertionWithError(error: Error, at index: Int = 0) {
            insertionCompletions[index](error)
        }
        
        func completeInsertionWithSuccess(at index: Int = 0) {
            insertionCompletions[index](nil)
        }
    }
    
    private func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: "any description", location: "anyLocation", imageURL: anyURL())
    }
    
    private func anyURL() -> String {
        "https://a-given-url.com"
    }
    
    private func anyError() -> NSError {
        NSError(domain: "Testing", code: 0)
    }
}
