//
//  FeedViewController.swift
//  EssentialFeedPrototype
//
//  Created by Ganuke Perera on 2024-05-03.
//

import Foundation
import UIKit

struct FeedImageViewModel {
    let description: String?
    let location: String?
    let imageName: String
}

final class FeedViewController: UITableViewController {
    
    private let imageSet = FeedImageViewModel.prototypeFeed
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return imageSet.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "FeedImageCell", for: indexPath) as? FeedImageCell else {
            return FeedImageCell(style: .default, reuseIdentifier: "FeedImageCell")
        }
        cell.configure(with: imageSet[indexPath.row])
        return cell
    }
}
