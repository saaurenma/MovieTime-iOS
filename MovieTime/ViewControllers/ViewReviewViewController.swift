//
//  ViewReviewViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 8/6/2022.
//

import UIKit
import Cosmos

/// A ViewController that holds a view that will popup when the user wishes to view a review for a particular movie.
class ViewReviewViewController: UIViewController {
    
    // Cosmos star rating outlet
    @IBOutlet weak var ratingCosmosView: CosmosView!
    
    @IBOutlet weak var reviewDescriptionLabel: UILabel!
    @IBOutlet weak var posterImageView: UIImageView!
    
    // The container of the popup that will be visible to the user. Contains the ratingCosmosView, reviewDescriptionLabel and posterImageView on the UI.
    @IBOutlet weak var containerView: UIView!
    
    // The review to be displayed to the user
    var currentMovieReview: [String:Any]?
    
    // The MovieData of the movie selected.
    var currentMovie: MovieData?
    
    
    override func viewDidLoad() {
        
        // set the popup to have rounded corners
        containerView.layer.cornerRadius = 10
        
        super.viewDidLoad()
        
        // set the poster thumbnail for the movie
        // if there is not a poster provided, then set it to a placeholder image.
        if let posterLink = currentMovie?.poster_path {
            posterImageView.sd_setImage(with: URL(string: "https://image.tmdb.org/t/p/w154"+posterLink))
        }
        else {
            posterImageView.image = UIImage(named: "backdropPlaceholderImage")
        }
        
        // set the rating and label text for the description
        ratingCosmosView.rating = currentMovieReview!["reviewScore"] as! Double
        if let reviewDescription = currentMovieReview!["reviewDescription"] as? String {
            reviewDescriptionLabel.text = reviewDescription
        }
        else {
            reviewDescriptionLabel.text = "None provided."
        }
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // dismiss the popup if the user goes to another screen
        self.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func dismiss(_ sender: Any) {
        // dismiss the popup if the user presses the dismiss button
        self.dismiss(animated: true, completion: nil)
    }
    

}
