//
//  FeedViewController.swift
//  EssentialFeedPrototype
//
//  Created by Ganuke Perera on 2024-05-03.
//

import Foundation
import UIKit

final class FeedViewController: UITableViewController {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "FeedImageCell", for: indexPath) 
        return cell
    }
}
