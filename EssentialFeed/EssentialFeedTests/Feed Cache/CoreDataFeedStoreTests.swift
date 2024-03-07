//
//  CoreDataFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-03-06.
//

import XCTest
import EssentialFeed

class CoreDataFeedStoreTests: XCTestCase, FeedStoreSpecs {
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
        
    }
    
    func test_saveCacheFeed_deliversNoErrorOnEmptyCache() {
    
    }
    
    func test_saveCacheFeed_deliversNoErrorOnNonEmptyCache() {
        
    }
    
    func test_saveCacheFeed_overidePreviouslyInsertedCacheValues() {
        
    }
    
    func test_delete_deliversNoErrorOnEmptyCache() {
        
    }
    
    func test_delete_hasNoSideEffectOnEmptyCache() {
        
    }
    
    func test_delete_emptiesPrviouslyInsertedCache() {
        
    }
    
    func test_storeSideEffects_runSerially() {
        
    }
    
    // MARK: Helpers
    
    func makeSUT(file: StaticString = #filePath, line: UInt = #line) -> FeedStore {
        let storeURL = URL(fileURLWithPath: "/dev/null")
        let sut = try! CoreDataFeedStore(storeURL: storeURL, bundle: Bundle(for: CoreDataFeedStore.self))
        trackMemoryLeaks(sut, file: file, line: line)
        return sut
    }
}
