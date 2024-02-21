//
//  FeedCachePolicy.swift
//  EssentialFeed
//
//  Created by Ganuke Perera on 2024-02-22.
//

import Foundation

final class FeedCachePolicy {
    private init() {}
    
    private static let calendar = Calendar(identifier: .gregorian)
    
    private static var maxAllowedCacheAgeInDays: Int {
        return 7
    }
    
    static func validateTime(_ time: Date, against: Date) -> Bool {
        guard let maxCacheDate = calendar.date(byAdding: .day, value: maxAllowedCacheAgeInDays, to: time) else {
            return false
        }
        return against < maxCacheDate
    }
}
