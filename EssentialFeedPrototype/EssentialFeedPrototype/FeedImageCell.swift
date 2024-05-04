//
//  FeedImageCell.swift
//  EssentialFeedPrototype
//
//  Created by Ganuke Perera on 2024-05-04.
//

import Foundation
import UIKit

final class FeedImageCell: UITableViewCell {

    @IBOutlet weak var feedImage: UIImageView!
    @IBOutlet weak var location: UILabel!
    @IBOutlet weak var locationContainer: UIStackView!
    @IBOutlet weak var imageDescription: UILabel!
    
    func configure(with model: FeedImageViewModel) {
        feedImage.image = UIImage(named: model.imageName)
        
        imageDescription.text = model.description
        imageDescription.isHidden = model.description == nil
        
        location.text = model.location
        locationContainer.isHidden = model.location == nil
    }
}
