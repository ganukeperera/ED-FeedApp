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
    
    //MARK: Helpers
    
    private func makeSUT(timestamp: @escaping () -> Date = Date.init, file: StaticString = #filePath, line: UInt = #line) -> (LocalFeedLoader, FeedStoreSpy) {
        let store = FeedStoreSpy()
        let sut = LocalFeedLoader(store: store, timestamp: timestamp)
        trackMemoryLeaks(store, file: file, line: line)
        trackMemoryLeaks(sut, file: file, line: line)
        return (sut, store)
    }
    
    private class FeedStoreSpy: FeedStore {
        typealias DeletionCompletion = (Error?) -> Void
        typealias InsertionCompletion = (Error?) -> Void
        private(set) var deletionCompletions = [DeletionCompletion]()
        private(set) var insertionCompletions = [InsertionCompletion]()
        private(set) var receivedMessages = [RecievedMessage]()
        
        enum RecievedMessage: Equatable {
            case deleteMessage
            case insertionMeessage([LocalFeedImage], Date)
        }
        
        func deleteCachedFeed(completion: @escaping DeletionCompletion) {
            receivedMessages.append(.deleteMessage)
            deletionCompletions.append(completion)
        }
        
        func saveCacheFeed(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
            receivedMessages.append(.insertionMeessage(feed, timestamp))
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
}
