//
//  FeedStoreSpy.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-02-15.
//

import Foundation
import EssentialFeed

class FeedStoreSpy: FeedStore {
    private(set) var deletionCompletions = [DeletionCompletion]()
    private(set) var insertionCompletions = [InsertionCompletion]()
    private(set) var retrivalCompletions = [RetrivalCompletion]()
    private(set) var receivedMessages = [ReceivedMessage]()
    
    enum ReceivedMessage: Equatable {
        case deleteMessage
        case insertionMeessage([LocalFeedImage], Date)
        case retrival
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
    
    func retrieve(completion: @escaping RetrivalCompletion) {
        receivedMessages.append(.retrival)
        retrivalCompletions.append(completion)
    }
    
    func completeRetrivalWithError(error: Error, at index: Int = 0) {
        retrivalCompletions[index](.failure(error))
    }
    
    func completeRetrivalWithSuccess(at index: Int = 0) {
        retrivalCompletions[index](.empty)
    }
    
    func completeRetrival(with feed: [LocalFeedImage], timestamp: Date, at index: Int = 0) {
        retrivalCompletions[index](.success(feed: feed, timeStamp: timestamp))
    }
}
