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
    
    func save(_ items: [FeedItem]) {
        store.deleteCachedFeed { [weak self] error in
            guard let self, error == nil else { return }
            self.store.saveCacheFeed(items: items, timestamp: timestamp())
        }
    }
}

class FeedStore {
    typealias DeletionCompletion = (Error?) -> Void
    private(set) var deleteCachedFeedCallCount = 0
    private(set) var insertCallCount = 0
    private(set) var completions = [DeletionCompletion]()
    var insertions = [(items: [FeedItem], timestamp: Date)]()
    
    func deleteCachedFeed(completion: @escaping DeletionCompletion) {
        completions.append(completion)
        deleteCachedFeedCallCount += 1
    }
    
    func saveCacheFeed(items: [FeedItem], timestamp: Date) {
        insertCallCount += 1
        insertions.append((items,timestamp))
    }
    
    func completeDeletionWithError(error: Error, at index: Int = 0) {
        completions[index](error)
    }
    
    func completeDeletionWithSuccess(at index: Int = 0) {
        completions[index](nil)
    }
}

final class CacheFeedCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUpOnCreation() {
        let (_, store) = makeSUT()
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
    
    func test_save_requestDeleteWhenRequestSave() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 1)
    }
    
    func test_save_deleteWithErrorDoesNotCallSave() {
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items)
        sut.store.completeDeletionWithError(error: anyError())
        
        XCTAssertEqual(store.insertCallCount, 0)
    }
    
    func test_save_deleteCacheWithSuccessCallSaveItems() {
        
        let (sut, store) = makeSUT()
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items)
        sut.store.completeDeletionWithSuccess()
        
        XCTAssertEqual(store.insertCallCount, 1)
    }
    
    func test_save_requestNewCacheInsertionWithTimestampOnSuccessfullDeletion() {
        let timestamp = Date()
        let (sut, store) = makeSUT(timestamp: { timestamp })
        let items = [uniqueItem(), uniqueItem()]
        
        sut.save(items)
        sut.store.completeDeletionWithSuccess()
        
        XCTAssertEqual(store.insertions.count, 1)
        XCTAssertEqual(store.insertions.first?.items, items)
        XCTAssertEqual(store.insertions.first?.timestamp, timestamp)
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
