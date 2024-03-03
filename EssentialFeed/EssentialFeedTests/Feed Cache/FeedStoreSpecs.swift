//
//  FeedStoreSpecs.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-03-03.
//

import Foundation

protocol FeedStoreSpecs {
    
    func test_retrieve_deliversEmptyDataOnEmptyResult()
    func test_retrieve_hasNoSideEffectOnEmptyCache()
    func test_retrieve_deliversFoundValuesOnNonEmptyCache()
    func test_retrieve_hasNoSideEffectOnNonEmptyCache()
    
    func test_saveCacheFeed_deliversNoErrorOnEmptyCache()
    func test_saveCacheFeed_deliversNoErrorOnNonEmptyCache()
    func test_saveCacheFeed_overidePreviouslyInsertedCacheValues()

    func test_delete_deliversNoErrorOnEmptyCache()
    func test_delete_hasNoSideEffectOnEmptyCache()
    func test_delete_emptiesPrviouslyInsertedCache()

    func test_storeSideEffects_runSerially()
}

protocol FailableRetrieveFeedStoreSpecs: FeedStoreSpecs {
    func test_retreive_deliversErrorOnRetrievalError()
    func test_retreive_hasNoSideEffectsOnFailure()
}

protocol FailableSaveCacheFeedFeedStoreSpecs: FeedStoreSpecs {
    func test_saveCacheFeed_deliversErrorOnInsertionError()
    func test_saveCacheFeed_hasNoSideEffectsOnInsertionError()
}

protocol FailableDeleteFeedFeedStoreSpecs: FeedStoreSpecs {
    func test_delete_deliversErrorOnDeletionError()
    func test_delete_noSideEffectsOnDeletionError()
}

typealias FailableFeedStoreSpecs = FailableRetrieveFeedStoreSpecs & FailableDeleteFeedFeedStoreSpecs & FailableDeleteFeedFeedStoreSpecs
