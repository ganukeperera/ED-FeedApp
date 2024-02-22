//
//  FeedCacheTestHelpers.swift
//  EssentialFeedTests
//
//  Created by Ganuke Perera on 2024-02-19.
//

import Foundation
import EssentialFeed

func uniqueImage() -> FeedImage {
    FeedImage(id: UUID(), description: "any description", location: "anyLocation", url: anyURL())
}

func uniqueImageFeed() -> (models: [FeedImage], local: [LocalFeedImage]) {
    let feed = [uniqueImage(), uniqueImage()]
    let localItems = feed.map { LocalFeedImage(id: $0.id, description: $0.description, location: $0.location, url: $0.url) }
    return (feed, localItems)
}

func anyURL() -> String {
    "https://a-given-url.com"
}

extension Date {
    func minusFeedCacheMaxAge() -> Date {
        addDate(days: -7)
    }
    
    func addDate(days: Int) -> Date {
        Calendar(identifier: .gregorian).date(byAdding: .day, value: days, to: self)!
    }
    
    func addSeconds(seconds: TimeInterval) -> Date {
        self + seconds
    }
}
