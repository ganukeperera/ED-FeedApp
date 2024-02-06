//
//  CacheFeedCaseTests.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-02-07.
//

import XCTest

class FeedStore {
    var deleteCachedFeedCallCount = 0
}

class LocalFeedLoader {
    let store: FeedStore
    init(store: FeedStore) {
        self.store = store
    }
}

final class CacheFeedCaseTests: XCTestCase {

    func test_init_doesNotDeleteCacheUpOnCreation() {
        let store = FeedStore()
        _ = LocalFeedLoader(store: store)
        
        XCTAssertEqual(store.deleteCachedFeedCallCount, 0)
    }
}
