//
//  XCTestCase+FailableRetrieveFeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-03-05.
//

import XCTest
import EssentialFeed

extension FailableRetrieveFeedStoreSpecs where Self: XCTestCase {
    
    func assertThatRetrieveDeliversErrorOnRetrievalError(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line) {
        
        expect(sut, toRetrieve: .failure(anyError()), file: file, line: line)
    }
    
    func assertTahtRetrieveHasNoSideEffectsOnFailure(on sut: FeedStore, file: StaticString = #filePath, line: UInt = #line){
        
        expect(sut, toRetrieveTwice: .failure(anyError()), file: file, line: line)
    }
}
