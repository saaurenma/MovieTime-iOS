//
//  ReviewViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 25/5/2022.
//

import UIKit
import Cosmos

/// This View Controller assists the user in appending a review to a movie being added to a user's watched movie list
class CreateReviewViewController: UIViewController {
    
    weak var databaseController: DatabaseProtocol?
    var currentMovie: MovieData?

    @IBOutlet weak var ratingCosmosView: CosmosView!
    @IBOutlet weak var descriptionTextField: UITextField!
    
    override func viewDidLoad() {
        // get access to the DatabaseProtocol instance defined in AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        super.viewDidLoad()
        
        // default number of stars will be 5
        ratingCosmosView.settings.totalStars = 5
        
    }
    
    
    /// Action connected to a button that when tapped, adds a review to the movie
    @IBAction func addReviewToMovie(_ sender: Any) {
        
        // Create an object with movieId, reviewScore and review description
        let movieToAdd = ["movieId":(currentMovie?.id)!, "reviewScore":Int(ratingCosmosView.rating), "reviewDescription":descriptionTextField.text!] as [String : Any]
        
        if descriptionTextField.text == "" {
            self.displayMessage(title: "Error", message: "A review description must be provided.")
            return
        }
            
        
        // Pass movieToAdd to a method in databaseController to add it to the database
        if databaseController?.addMovieWatchedToUser(movie: movieToAdd) == false {
            // Display the message if the movie has already been added
            self.displayMessage(title: "Error", message: "This movie has already been added to the list")
        }
        else {
            // Switched to the user's watched movie list to show the newly added movie
            self.navigationController?.popViewController(animated: true)
            self.tabBarController?.selectedIndex = 1
        }
        

        
    }
    

}
