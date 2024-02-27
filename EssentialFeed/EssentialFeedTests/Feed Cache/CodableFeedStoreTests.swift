//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-02-24.
//

import XCTest
import EssentialFeed

class CodableFeedStore: FeedStore {
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
    
    func saveCacheFeed(_ feed: [LocalFeedImage], timestamp: Date, completion: @escaping InsertionCompletion) {
        let codableLocalFeed = feed.map { CodableFeedImage($0)}
        let cache = Cache(feed: codableLocalFeed, timestamp: timestamp)
        do {
            let encodedObject = try JSONEncoder().encode(cache)
            try encodedObject.write(to: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
    
    func retrieve(completion: @escaping RetrivalCompletion) {
        guard let data = try? Data(contentsOf: storeURL) else {
            completion(.empty)
            return
        }
        do{
            let cache = try JSONDecoder().decode(Cache.self, from: data)
            let feed = cache.feed.map { $0.localFeed }
            completion(.success(feed: feed, timeStamp: cache.timestamp))
        } catch {
            completion(.failure(error))
        }
    }
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        let fileManager = FileManager.default
        guard fileManager.fileExists(atPath: storeURL.path) else { return completion(nil) }
        do {
            try fileManager.removeItem(at: storeURL)
            completion(nil)
        } catch {
            completion(error)
        }
    }
}

final class CodableFeedStoreTests: XCTestCase {
    override func setUp() {
        super.setUp()
        
        setupEmptyStoreState()
    }
    
    override func tearDown() {
        super.tearDown()
        
        undoStoreSideEffects()
    }

    func test_retrieve_deliversEmptyDataOnEmptyResult() {
        let sut = makeSUT()
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        
        expect(sut, toRetrieveTwice: .empty)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed, timestamp: timestamp, to: sut)
        
        expect(sut, toRetrieve: .success(feed: feed, timeStamp: timestamp))
    }
    
    func test_retrieve_hasNoSideEffectOnNonEmptyCache() {
        let sut = makeSUT()
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        insert(feed, timestamp: timestamp, to: sut)
        
        expect(sut, toRetrieveTwice: .success(feed: feed, timeStamp: timestamp))
    }
    
    func test_retreive_deliversErrorOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL)
        
        try! "invalid Data".write(to: storeURL, atomically: true, encoding: .utf8)
        
        expect(sut, toRetrieve: .failure(anyError()))
    }
    
    func test_retreive_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL)
        
        try! "invalid Data".write(to: storeURL, atomically: true, encoding: .utf8)
        
        expect(sut, toRetrieveTwice: .failure(anyError()))
    }
    
    func test_saveCacheFeed_canOveridePreviouslyInsertedCacheValues() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL)
        
        let firstInsertionError = insert(uniqueImageFeed().local, timestamp: Date(), to: sut)
        XCTAssertNil(firstInsertionError, "Expect feed to be insert successfuly")
        
        let feed = uniqueImageFeed().local
        let timestamp = Date()
        
        let secondInsertionError = insert(feed, timestamp: timestamp, to: sut)
        XCTAssertNil(secondInsertionError, "Expect feed to be insert successfuly")
        expect(sut, toRetrieve: .success(feed: feed, timeStamp: timestamp))
    }
    
    func test_saveCacheFeed_deliversErrorOnInsertionError() {
        let storeURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL)
        
        let firstInsertionError = insert(uniqueImageFeed().local, timestamp: Date(), to: sut)
        
        XCTAssertNotNil(firstInsertionError, "Expected insertion error on invalid store url ")
    }
    
    func test_delete_hasNoSideEffectOnEmptyCache() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL)
        
        let deletionError = delete(sut)
        XCTAssertNil(deletionError, "Expected non-empty cache deletion to succeed")
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_emptiesPrviouslyInsertedCache() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL)
        
        let firstInsertionError = insert(uniqueImageFeed().local, timestamp: Date(), to: sut)
        XCTAssertNil(firstInsertionError)
        
        let deletionError = delete(sut)
        XCTAssertNil(deletionError, "Expected cache deletion to succeed")
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let noPermissionURL = cacheDirectory()
        let sut = makeSUT(noPermissionURL)
        
        let deletionError = delete(sut)
        XCTAssertNotNil(deletionError, "Should deliver error on deletion fon non permitted URL")
    }
    
    // - MARK: Helpers
    func delete(_ sut: FeedStore) -> Error? {
        let exp = expectation(description: "wait for deletion on empty cache")
        var deletionError: Error?
        sut.deleteCachedFeed { error in
            deletionError = error
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return deletionError
    }
    
    @discardableResult
    private func insert(_ feed: [LocalFeedImage], timestamp: Date, to sut: FeedStore) -> Error? {
        let exp = expectation(description: "waiting for retrieve to complete")
        var insertionError: Error?
        sut.saveCacheFeed(feed, timestamp: timestamp) { receivedError in
            insertionError = receivedError
            exp.fulfill()
        }
        wait(for: [exp], timeout: 1.0)
        return insertionError
    }
    
    private func expect(_ sut: FeedStore, toRetrieveTwice expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
        expect(sut, toRetrieve: expectedResult, file: file, line: line)
    }
    
    private func expect(_ sut: FeedStore, toRetrieve expectedResult: RetrieveCachedFeedResult, file: StaticString = #filePath, line: UInt = #line) {
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
    
    private func makeSUT(_ storeURL: URL? = nil, file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let storeURL = storeURL ?? testSpecificStoreURL()
        let sut = CodableFeedStore(storeURL: storeURL)
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
    
    private func testSpecificStoreURL() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!.appendingPathExtension("\(type(of: self)).store")
    }
    
    private func cacheDirectory() -> URL {
        return FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask).first!
    }
    
    private func setupEmptyStoreState() {
        deleteStoreArtifacts()
    }
    
    private func undoStoreSideEffects() {
        deleteStoreArtifacts()
    }
    
    private func deleteStoreArtifacts() {
        try? FileManager.default.removeItem(at: testSpecificStoreURL())
    }
}
