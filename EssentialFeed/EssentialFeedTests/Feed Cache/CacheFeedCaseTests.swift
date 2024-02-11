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
            completion(error)
            guard let self, error == nil else { return }
            self.store.saveCacheFeed(items: items, timestamp: timestamp())
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    private(set) var deletionCompletions = [DeletionCompletion]()
    private(set) var receivedMessages = [RecievedMessage]()
    
    enum RecievedMessage: Equatable {
        case deleteMessage
        case insertionMeessage([FeedItem], Date)
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        receivedMessages.append(.deleteMessage)
        deletionCompletions.append(completion)
    }
    
    func saveCacheFeed(items: [FeedItem], timestamp: Date) {
        receivedMessages.append(.insertionMeessage(items, timestamp))
    }
    
    func completeDeletionWithError(error: Error, at index: Int = 0) {
        deletionCompletions[index](error)
    }
    
    func completeDeletionWithSuccess(at index: Int = 0) {
        deletionCompletions[index](nil)
    }
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
        sut.store.completeDeletionWithError(error: anyError())
        
        XCTAssertEqual(store.receivedMessages, [.deleteMessage])
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(timestamp: { timestamp })
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items) { _ in }
        sut.store.completeDeletionWithSuccess()
        
        XCTAssertEqual(store.receivedMessages, [.deleteMessage, .insertionMeessage(items, timestamp)])
    }
    
    func test_save_deliverAnErrorWhenDeletionFailure() {
        let timestamp = Date()
        let (sut, store) = makeSUT(timestamp: { timestamp })
        let items = [uniqueItem(), uniqueItem()]
        let expectedError = anyError()
        
        var receivedError: Error?
        let expectation = expectation(description: "wait for insertion completion")
        sut.save(items) { error in
            receivedError = error
            expectation.fulfill()
        }
        store.completeDeletionWithError(error: expectedError)
        wait(for: [expectation], timeout: 1.0)
        
        XCTAssertEqual(expectedError, receivedError as? NSError)
    }
    
    //MARK: Helpers
    
    func makeSUT(timestamp: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStore) {
        let store = FeedStore()
        let sut = LocalFeedLoader(store: store, timestamp: timestamp)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    func uniqueItem() -> FeedItem {
        FeedItem(id: UUID(), description: "any description", location: "anyLocation", imageURL: anyURL())
    }
    
    private func anyURL() -> String {
        "https://a-given-url.com"
    }
    
    private func anyError() -> NSError {
        NSError(domain: "Testing", code: 0)
    }
}
