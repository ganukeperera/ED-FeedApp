//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-02-24.
//

import XCTest
import EssentialFeed

final class CodableFeedStoreTests: XCTestCase, FailableFeedStoreSpecs {
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
        
        assertThatRetrieveDeliversEmptyOnEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveHasNoSideEffectOnEmptyCache(on: sut)
    }
    
    func test_retrieve_deliversFoundValuesOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetrieveDeliversFoundValuesOnNonEmptyCache(on: sut)
    }
    
    func test_retrieve_hasNoSideEffectOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatRetreiveHasNoSideEffectOnNonEmptyCache(on: sut)
    }
    
    func test_retreive_deliversErrorOnRetrievalError() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL)
        
        try! "invalid Data".write(to: storeURL, atomically: true, encoding: .utf8)
        
        assertThatRetrieveDeliversErrorOnRetrievalError(on: sut)
    }
    
    func test_retreive_hasNoSideEffectsOnFailure() {
        let storeURL = testSpecificStoreURL()
        let sut = makeSUT(storeURL)
        
        try! "invalid Data".write(to: storeURL, atomically: true, encoding: .utf8)
        
        assertTahtRetrieveHasNoSideEffectsOnFailure(on: sut)
    }
    
    func test_saveCacheFeed_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatInsertDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_saveCacheFeed_deliversNoErrorOnNonEmptyCache() {
        let sut = makeSUT()
        
        assertThatInsertDeliversNoErrorOnNonEmptyCache(on: sut)
    }
    
    func test_saveCacheFeed_overidePreviouslyInsertedCacheValues() {
        let sut = makeSUT()
        
        assertThatInsertOveridePreviouslyInsertedCacheValues(on: sut)
    }
    
    func test_saveCacheFeed_deliversErrorOnInsertionError() {
        let storeURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL)
        
        let firstInsertionError = insert(uniqueImageFeed().local, timestamp: Date(), to: sut)
        
        XCTAssertNotNil(firstInsertionError, "Expected insertion error on invalid store url ")
    }
    
    func test_saveCacheFeed_hasNoSideEffectsOnInsertionError() {
        let storeURL = URL(string: "invalid://store-url")!
        let sut = makeSUT(storeURL)
        
        insert(uniqueImageFeed().local, timestamp: Date(), to: sut)
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        let sut = makeSUT()

        assertThatDeleteDeliversNoErrorOnEmptyCache(on: sut)
    }
    
    func test_delete_hasNoSideEffectOnEmptyCache() {
        let sut = makeSUT()
        
        assertThatDeleteHasNoSideEffectOnEmptyCache(on: sut)
    }
    
    func test_delete_emptiesPrviouslyInsertedCache() {
        let sut = makeSUT()
        
        assertThatDeleteEmptiesPrviouslyInsertedCache(on: sut)
    }
    
    func test_delete_deliversErrorOnDeletionError() {
        let noPermissionURL = cacheDirectory()
        let sut = makeSUT(noPermissionURL)
        
        let deletionError = delete(sut)
        XCTAssertNotNil(deletionError, "Should deliver error on deletion fon non permitted URL")
    }
    
    func test_delete_noSideEffectsOnDeletionError() {
        let noPermissionURL = cacheDirectory()
        let sut = makeSUT(noPermissionURL)
        
        delete(sut)
        
        expect(sut, toRetrieve: .empty)
    }
    
    func test_storeSideEffects_runSerially() {
        let sut = makeSUT()
        
        assertThatStoreSideEffectsRunSerially(on: sut)
    }
    
    // - MARK: Helpers

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
