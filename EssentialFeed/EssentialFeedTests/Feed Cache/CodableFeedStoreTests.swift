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
        let feed: [CodableFeedImage]
        let timestamp: Date
    }
    
    private struct CodableFeedImage: Codable {
        private let id: UUID
        private let description: String?
        private let location: String?
        private let url: String
        
        init(_ localFeedImage: LocalFeedImage) {
            id = localFeedImage.id
            description = localFeedImage.description
            location = localFeedImage.location
            url = localFeedImage.url
        }
        
        var localFeed: LocalFeedImage {
            return LocalFeedImage(id: id, description: description, location: location, url: url)
        }
    }
    
    private let storeURL: URL
    
    init(storeURL: URL) {
        self.storeURL = storeURL
    }
    
    func saveCacheFeed(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping FeedStore.InsertionCompletion) {
        let codableLocalFeed = feed.map { CodableFeedImage($0)}
        let cache = Cache(feed: codableLocalFeed, timestamp: timestamp)
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
        let feed = cache.feed.map { $0.localFeed }
        completion(.success(feed: feed, timeStamp: cache.timestamp))
    }
}

final class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        let storeURL = testSpecificStoreURL()
        try? FileManager.default.removeItem(at: storeURL)
    }
    
    override func tearDown() {
        super.tearDown()
        
        let storeURL = testSpecificStoreURL()
        try? FileManager.default.removeItem(at: storeURL)
    }

    func test_retrieve_deliversEmptyDataOnEmptyResult() {
        let sut = makeSUT()
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
        let sut = makeSUT()
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
        let sut = makeSUT()
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
    
    // - MARK: Helpers
    
    private func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> CodableFeedStore {
        let storeURL = testSpecificStoreURL()
        let sut = CodableFeedStore(storeURL: storeURL)
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathExtension("\(type(of: self)).store")
    }
}
