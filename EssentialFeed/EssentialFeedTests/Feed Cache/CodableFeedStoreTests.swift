//
//  CodableFeedStoreTests.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-02-24.
//

import XCTest
import EssentialFeed

class CodableFeedStore {
    func retrieve(completion: @escaping FeedStore.RetrivalCompletion) {
        completion(.empty)
    }
}

final class CodableFeedStoreTests: XCTestCase {

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
}
