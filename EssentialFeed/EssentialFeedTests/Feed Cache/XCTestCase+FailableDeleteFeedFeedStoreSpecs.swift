//
//  XCTestCase+FailableDeleteFeedFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-03-05.
//


import XCTest
import EssentialFeed

extension FailableDeleteFeedStoreSpecs where Self: XCTestCase {
    
    func assertThatDeleteDeliversErrorOnDeletionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        let deletionError = delete(sut)

        XCTAssertNotNil(deletionError, "Expected cache deletion to fail", file: file, line: line)
    }

    func assertThatDeleteHasNoSideEffectsOnDeletionError(on sut: FeedStore, file: StaticString = #file, line: UInt = #line) {
        delete(sut)

        expect(sut, toRetrieve: .empty, file: file, line: line)
    }
}
