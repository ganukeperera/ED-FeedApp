//
//  XCTestCase+FailableSaveCacheFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-03-05.
//

import XCTest
import EssentialFeed

extension FailableSaveCacheFeedFeedStoreSpecs where Self: XCTestCase {
    
    func assertThatInsertDeliversErrorOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let insertionError = insert(uniqueImageFeed().local, timestamp: Date(), to: sut)

        XCTAssertNotNil(insertionError, "Expected cache insertion to fail with an error", file: file, line: line)
    }

    func assertThatInsertHasNoSideEffectsOnInsertionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        insert(uniqueImageFeed().local, timestamp: Date(), to: sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
}

