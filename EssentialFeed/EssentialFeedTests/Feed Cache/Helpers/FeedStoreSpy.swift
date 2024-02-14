//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-02-15.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
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
