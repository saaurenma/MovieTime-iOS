//
//  MovieInformationViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 28/4/2022.
//

import UIKit
import SDWebImage
import YouTubeiOSPlayerHelper

/// Custom class for the View Controller that displays movie information
class MovieInformationViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource {
    
    // The current movie being displayed
    var currentMovie: MovieData?
    
    
    // Lists of Actors and Crew
    var allActors = [ActorData]()
    var allCrew = [CrewData]()
    // Similar movies and videos found
    var allSimilarMovies = [MovieData]()
    var allVideos = [VideoData]()
    
    // Relevant outlets to display information
    @IBOutlet weak var backdropImageView: UIImageView!
    @IBOutlet weak var overviewLabel: UILabel!
    @IBOutlet weak var releaseDateLabel: UILabel!
    @IBOutlet weak var directorLabel: UILabel!
    @IBOutlet weak var showtimesButton: UIBarButtonItem!
    @IBOutlet weak var castCollectionView: UICollectionView!
    @IBOutlet weak var similarMovieCollectionView: UICollectionView!
    @IBOutlet weak var trailerYoutubeView: YTPlayerView!
    @IBOutlet weak var videoLoadingLabel: UILabel!
    
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
        allSimilarMovies = []
        allCrew = []
        allActors = []
        allVideos = []
        
        // Get access to DatabaseProtocol instanciated in AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        
        Task {
            await requestCastByMovieID(movieId: (currentMovie?.id)!)
            await requestSimilarMovies(movieId: (currentMovie?.id)!)
            await requestVideos(movieId: (currentMovie?.id)!)
            if allVideos.count != 0 && allVideos[0].site == "YouTube"{
                trailerYoutubeView.load(withVideoId: allVideos[0].key!)
            }
            else {
                videoLoadingLabel.text = "Preview unvailable."
            }
            
            
            // Pull additional data from TheMovieDB that was not available from their provided Search API
            currentMovie = await requestMovieDataById(movieId: (currentMovie?.id!)!)
            
            // If the movie is not released, do not allow the user to view showtimes for the movie
            if currentMovie?.status != "Released" {
                showtimesButton.isEnabled = false
            }
            else {
                showtimesButton.isEnabled = true
            }
            
            // Get an array of directors of the movie
            let directors = allCrew.filter{
                $0.job == "Director"
            }
            
            // Append the director names to an array of Strings
            var directorNames: [String] = []
            for director in directors {
                directorNames.append(director.name!)
            }
            
            // Display the directors seperated with a comma if there are more than one
            if directorNames != []{
                directorLabel.text = directorNames.joined(separator: ", ")
            }
            else {
            // If there are no directors, indicate that none were found
                directorLabel.text = "Not Found"
            }
            
            super.viewDidLoad()
            
        }
        
        // Set the View Controller title to the title of the movie
        self.title = currentMovie?.title
        
        // Download and set the image for the backdrop of the movie
        let imageRootURL = "https://image.tmdb.org/t/p/w780"
        if let backdropLink = currentMovie?.backdrop_path {
            backdropImageView.sd_setImage(with: URL(string: imageRootURL+backdropLink))
        }
        else {
        // If there is no backdrop path available, display a placeholder image
            backdropImageView.image = UIImage(named: "backdropPlaceholderImage")
        }
        
        overviewLabel.text = currentMovie?.overview
        releaseDateLabel.text = dateFormatter(stringDate: currentMovie?.release_date ?? "")
        
        // Set the delegate and dataSource of the castCollectionView to the current class
        castCollectionView.delegate = self
        castCollectionView.dataSource = self
        
        similarMovieCollectionView.delegate = self
        similarMovieCollectionView.dataSource = self
        
        // Set castCollectionView to have rounded corners
        castCollectionView.layer.cornerRadius = 12
        similarMovieCollectionView.layer.cornerRadius = 12
        
    }
    
    
    /// Performs a segue to the Showtimes View Controller
    @IBAction func viewShowtimes(_ sender: Any) {
        performSegue(withIdentifier: "showShowtimes", sender: nil)
        
    }
    
    /// Formats a string date to dd/MM/yyyy format
    /// - Parameter stringDate: The string containing the date
    /// - Returns: A date string in the format of dd/MM/yyyy
    func dateFormatter(stringDate: String) -> String {
        
        guard stringDate != "" else {
            return "Not Found"
        }
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateFormat = "yyyy-MM-dd"
        
        
        let date = dateFormatter.date(from:stringDate)!
        
        dateFormatter.dateFormat = "dd/MM/yyyy"
        let formattedDateString = dateFormatter.string(from: date)
        return formattedDateString
    }
    
    func requestVideos(movieId: Int) async {
        
        // Construct URL to get videos
        var similarMovieURLComponents = URLComponents()
        similarMovieURLComponents.scheme = "https"
        similarMovieURLComponents.host = "api.themoviedb.org"
        // Pass movieId
        similarMovieURLComponents.path = "/3/movie/" + "\(movieId)" + "/videos"
        similarMovieURLComponents.queryItems = [
            
            URLQueryItem(name: "api_key", value: ""),
            URLQueryItem(name: "language", value: "en-US"),
            
        ]
        
        // Exit function if URL is invalid
        guard let requestURL = similarMovieURLComponents.url else {
            return
        }
        
        let urlRequest = URLRequest(url: requestURL)
        
        do {
            // download the data
            let  (data, _) = try await URLSession.shared.data(for: urlRequest)
            
            // Decode the downloaded data using SearchData
            let decoder = JSONDecoder()
            let videoRequestData = try decoder.decode(VideoRequestData.self, from: data)
            
            if let videoData = videoRequestData.results {
                await MainActor.run {
                    // Append contents of datasets to appropriate arrays
                    allVideos.append(contentsOf: videoData)
                    
                }
            }
            
        }
        
        catch let error {
            print(error)
        }
    }
    
    /// Populates allSimilarMovies for a given movieId from TheMovieDB API.
    /// - Parameter movieId: The movie Id number defined in the theMovieDB database of type Integer.
    func requestSimilarMovies(movieId: Int) async {
        
        // Construct URL to get similar movies
        var similarMovieURLComponents = URLComponents()
        similarMovieURLComponents.scheme = "https"
        similarMovieURLComponents.host = "api.themoviedb.org"
        // Pass movieId
        similarMovieURLComponents.path = "/3/movie/" + "\(movieId)" + "/similar"
        similarMovieURLComponents.queryItems = [
            
            URLQueryItem(name: "api_key", value: ""),
            URLQueryItem(name: "language", value: "en-US"),
            URLQueryItem(name: "page", value: "1")

        ]
        
        // Exit function if URL is invalid
        guard let requestURL = similarMovieURLComponents.url else {
            return
        }
        
        let urlRequest = URLRequest(url: requestURL)
        
        do {
            // download the data
            let  (data, _) = try await URLSession.shared.data(for: urlRequest)
            
            // Decode the downloaded data using SearchData
            let decoder = JSONDecoder()
            let similarMovieData = try decoder.decode(SearchData.self, from: data)
            
            if let similarMovies = similarMovieData.results {
                await MainActor.run {
                    // Append contents of datasets to appropriate arrays
                    allSimilarMovies.append(contentsOf: similarMovies)
                    similarMovieCollectionView.reloadData()
                    
                }
            }
            
        }
        
        catch let error {
            print(error)
        }
        
        
    }
    
    
    /// Populates allCrew and allActors arrays for a given movieId from TheMovieDB API.
    /// - Parameter movieId: The movie Id number defined in the theMovieDB database of type Integer.
    func requestCastByMovieID(movieId: Int) async {
        
        // Construct URL to get cast
        var castURLComponents = URLComponents()
        castURLComponents.scheme = "https"
        castURLComponents.host = "api.themoviedb.org"
        // Pass movieId
        castURLComponents.path = "/3/movie/" + "\(movieId)" + "/credits"
        castURLComponents.queryItems = [
            
            URLQueryItem(name: "api_key", value: ""),
            URLQueryItem(name: "language", value: "en-US")
            
        ]
        
        // Exit function if URL is invalid
        guard let requestURL = castURLComponents.url else {
            return
        }
        
        let urlRequest = URLRequest(url: requestURL)
        
        do {
            // download the data
            let  (data, _) = try await URLSession.shared.data(for: urlRequest)
            
            // Decode the downloaded data using CastData
            let decoder = JSONDecoder()
            let castData = try decoder.decode(CastData.self, from: data)
            
            if let actors = castData.cast, let crew = castData.crew{
                await MainActor.run {
                    // Append contents of datasets to appropriate arrays
                    allActors.append(contentsOf: actors)
                    allCrew.append(contentsOf: crew)
                    castCollectionView.reloadData()
                    
                }
            }
            
        }
        
        catch let error {
            print(error)
        }
        
        
    }
    
    
    // CAST COLLECTION VIEW CODE
    
    /// Tells the castCollectionView of how many number of cells to display in the collection view.
    /// - Parameters:
    ///   - collectionView: The castCollectionView which will display the actors of the movie.
    ///   - section:An index number identifying a section in collectionView. This will be always 0 because the castCollectionView only has 1 section.
    /// - Returns: The number of cells to display in the collection view.
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        if collectionView == self.castCollectionView {
            // the number of items in the collection view will be the number of actors returned by the API
            return allActors.count
        }
        else if collectionView == self.similarMovieCollectionView {
            // the number of similar movies returned by TheMovieDB
            return allSimilarMovies.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        let imageRootURL = "https://image.tmdb.org/t/p/w185"

        
        if collectionView == self.castCollectionView {
            // Cast cell to CastCollectionViewCel
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "actorCell", for: indexPath) as! CastCollectionViewCell
            
            // Get the actor for the cell
            let actor = allActors[indexPath.row]
            
            // If there is a profile picture for the actor, set the imageView in the cell to it
            if let actorImagePath = actor.profile_path {
                cell.castImageView.sd_setImage(with: URL(string: imageRootURL+actorImagePath))
            }
            
            else {
                // If there is not a profile picture, then set it to a placeholder image
                cell.castImageView.image = UIImage(named: "profilePlaceholderImage")
            }
            // If there is a name for the actor, set the label in the cell to it
            if let actorName = actor.name {
                cell.castNameLabel.text = actorName
            }
            
            // If there is a character for the actor, set the label in the cell to it
            if let actorCharacter = actor.character{
                cell.castCharacterLabel.text = actorCharacter
            }
            
            // Format cell
            cell.layer.borderColor = UIColor.systemGray6.cgColor
            cell.layer.borderWidth = 5
            cell.layer.cornerRadius = 12
            cell.layer.backgroundColor = UIColor(named: "collectionViewColour")?.cgColor
            
            return cell
        }
        
        else if collectionView == self.similarMovieCollectionView {
            // Cast cell to SimilarMoviesCollectionViewCell
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "movieCell", for: indexPath) as! SimilarMoviesCollectionViewCell
            
            // Get the movie for the cell
            let movie = allSimilarMovies[indexPath.row]
            
            // If there is a poster picture for the movie, set the imageView in the cell to it
            if let moviePosterPath = movie.poster_path {
                cell.moviePosterImageView.sd_setImage(with: URL(string: imageRootURL+moviePosterPath))
            }
            else {
                // If there is not a picture, then set it to a placeholder image
                cell.moviePosterImageView.image = UIImage(named: "profilePlaceholderImage")
            }
            // If there is a title for the movie, set the label in the cell to it
            if let movieTitle = movie.title {
                cell.movieTitleLabel.text = movieTitle
            }
            
            // Format cell
            cell.layer.borderColor = UIColor.systemGray6.cgColor
            cell.layer.borderWidth = 5
            cell.layer.cornerRadius = 12
            cell.layer.backgroundColor = UIColor(named: "collectionViewColour")?.cgColor
            
            return cell
        }
        
        return UICollectionViewCell()
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == self.similarMovieCollectionView {
            currentMovie = allSimilarMovies[indexPath.row]
            self.viewDidLoad()
            self.viewWillAppear(true)
            self.similarMovieCollectionView.reloadData()
            self.castCollectionView.reloadData()
            
        }

    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    
    /// Action that is called when a user wants to add a movie to their list of movies
    @IBAction func addToList(_ sender: Any) {
        showAddMovieActionSheet()
    }
    
    
    
    /// Creates and displays an ActionSheet with options of which list the user would like to add it to.
    func showAddMovieActionSheet() {
        let actionSheet = UIAlertController(title: "Add Movie", message: nil, preferredStyle: .actionSheet)
        actionSheet.addAction(UIAlertAction(title: "Add as Movie to Watch", style: .default, handler: { [self] action in
            // If the movie has already been added display a message to the user notifying them of this
            if databaseController?.addMovieToWatchToUser(movieId: (currentMovie?.id)!) == false {
                self.displayMessage(title: "Error", message: "This movie has already been added to the list")
            }
            else {
                // Switch to the index in the tabbar controller where the user added the movie
                self.tabBarController?.selectedIndex = 2
            }
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Add as Watched Movie", style: .default, handler: { [self] action in
            // Segue to the Create Review Screen where the user will be prompted to add a review to their watched movie
            performSegue(withIdentifier: "showReviewScreen", sender: nil)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
            print("Cancel addition of movie")
            
        }))
        
        present(actionSheet, animated: true)
    }
    
    // MARK: - Navigation
    
    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "showReviewScreen" {
            if let destination = segue.destination as? CreateReviewViewController {
                destination.currentMovie = currentMovie
            }
        }
        
        else if segue.identifier == "showShowtimes" {
            if let destination = segue.destination as? ShowtimesTableViewController {
                destination.currentMovie = currentMovie
                
            }
        }
    }
    
}
