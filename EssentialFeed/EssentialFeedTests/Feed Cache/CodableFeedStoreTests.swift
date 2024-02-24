//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-02-24.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    private struct Cache: Codable {
        let feed: [LocalFeedImage]
        let timestamp: Date
    }
    
    private let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathExtension("image-feed.store")
    
    func saveCacheFeed(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let cache = Cache(feed: feed, timestamp: timestamp)
        let encodedObject = try! JSONEncoder().encode(cache)
        try! encodedObject.write(to: storeURL)
        completion(nil)
    }
    
    func retrieve(completion: @escaping FeedStore.RetrivalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }
        let cache = try! JSONDecoder().decode(Cache.self, from: data)
        completion(.success(feed: cache.feed, timeStamp: cache.timestamp))
    }
}

final class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathExtension("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    override func tearDown() {
        super.tearDown()
        
        let storeURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.appendingPathExtension("image-feed.store")
        try? FileManager.default.removeItem(at: storeURL)
    }

    func test_retrieve_deliversEmptyDataOnEmptyResult() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "waiting for retrieve to complete")
        
        sut.retrieve { result in
            switch result {
            case .empty:
                break
            default:
                XCTFail("expected empty result but received \(result) instead")
            }
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "waiting for retrieve to complete")
        
        sut.retrieve { firstResult in
            sut.retrieve { secondResult in
                switch (firstResult, secondResult) {
                case (.empty, .empty):
                    break
                default:
                    XCTFail("expected empty results but received \(firstResult) and \( secondResult)instead")
                }
                exp.fulfill()
            }
        }
        wait(for: [exp], timeout: 1.0)
    }
    
    func test_retrieveAfterInsertingToEmptyCache_deliversDataWhenCacheIsNotEmpty() {
        let sut = CodableFeedStore()
        let exp = expectation(description: "waiting for retrieve to complete")
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        sut.saveCacheFeed(feed, timestamp: timestamp) { insertionError in
            XCTAssertNil(insertionError, "Expected to insert error successfully")
            sut.retrieve { result in
                switch result {
                case let .success(retrievedFeed, receivedTimestamp):
                    XCTAssertEqual(retrievedFeed, feed)
                    XCTAssertEqual(receivedTimestamp, timestamp)
                default:
                    XCTFail("expected success but received \(result) instead")
                }
                exp.fulfill()
            }
        }
        
        wait(for: [exp], timeout: 1.0)
    }
}
