//
//  MovieTableViewCell.swift
//  MovieTime
//
//  Created by Saauren Mankad on 28/4/2022.
//

import UIKit

/// Defines a cell for the movie search functionality
class SearchMovieTableViewCell: UITableViewCell {
    
    // Movie poster and movie title outlets
    @IBOutlet weak var moviePosterImageView: UIImageView!
    @IBOutlet weak var movieTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }

    override func setSelected(_ selected: Bool, animated: Bool) {
        super.setSelected(selected, animated: animated)

    }

}
