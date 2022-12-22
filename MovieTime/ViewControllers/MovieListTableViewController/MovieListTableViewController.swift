//
//  WatchedMoviesTableViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 12/5/2022.
//

import UIKit
import UserNotifications

/// Holds the type of list to be displayed by the MovieListTableViewController.
/// - currentUserWatched is used when the list to be displayed is the current user of the application's watched list of movies.
/// - currentUserToWatch is used when the list to be displayed is the current user of the application's list of movies to watch.
/// - publicUserWatched is used when the list to be displayed is another public user's watched list of movies.
/// - publicUserToWatch is used when the list to be displayed is another public user's list of movies to watch.
/// - downloadedToWatch is used to display the locally saved list of movies to watch
/// - downloadedWatched Watched is used to display the locally saved list of movies watched
enum MovieListType {
    case currentUserWatched
    case currentUserToWatch
    case publicUserWatched
    case publicUserToWatch
    case downloadedToWatch
    case downloadedWatched
}


/// Custom TableView Controller class defining the movie lists of the current user, or other users that have an account on the app and do not have privacy enabled in settings.
/// Inherits DatabaseListener such that the class can listen to changes in movieLists and update the movieList array as required.
class MovieListTableViewController: UITableViewController, DatabaseListener {
    
    /// Set the listenerType to movies to listen to changes to the movieList.
    var listenerType: ListenerType = .movies
    
    /// listType of type MovieListType will hold one of currentUserWatched, currentUserToWatch, publicUserWatched or publicUserToWatch
    var listType: MovieListType?

    
    var movieList: [[String:Any]] = []
    var filteredMovieList: [[String:Any]] = []
    
    static let NOTIFICATION_IDENTIFIER = "monash.edu.MovieTime"
    
    lazy var appDelegate = {
       return UIApplication.shared.delegate as! AppDelegate
    }()
    
    weak var databaseController: DatabaseProtocol?
    
    // the public user selected to view the movies of
    var selectedUser: User?
    
    // the selected movie in the list by the user
    var selectedMovie: MovieData?
    
    
    // the selected movieid attached to reviewdata by the user who is the owner of the list
    var selectedMovieReview: [String:Any]?
    
    // outlet for bar button
    @IBOutlet weak var downloadBarButton: UIBarButtonItem!
    
    // setup userdefaults reference
    let userDefaults = UserDefaults.standard

    
    override func viewDidLoad() {
        
        // get access to the database protocol instance defined in AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        super.viewDidLoad()
        
        // change navigation item title based on which list type is being viewed
        // for publicUserToWatch and publicUserWatched, the public user's usernames are included
        if listType == .currentUserToWatch {
            self.navigationItem.title = "Movies to Watch"
        }
        else if listType == .currentUserWatched {
            self.navigationItem.title = "Watched Movies"
            
        }
        else if listType == .publicUserToWatch {
            self.navigationItem.title = "\(selectedUser!.username ?? ""): To Watch List"
            // user can only download their own lists for offline viewing
            self.navigationItem.rightBarButtonItem = nil

        }
        else if listType == .publicUserWatched {
            self.navigationItem.title = "\(selectedUser?.username ?? ""): Watched List"
            // user can only download their own lists for offline viewing
            self.navigationItem.rightBarButtonItem = nil

        }
        
        else if listType == .downloadedWatched {
            self.navigationItem.title = "Downloaded Watched List"
        }
        
        else if listType == .downloadedToWatch {
            self.navigationItem.title = "Downloaded To Watch List"
        }
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // add the class as a listener to the database controller when the ViewController appears
        databaseController?.addListener(listener: self)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // remove the class as a listener to the database controller when the ViewController disappears
        databaseController?.removeListener(listener: self)
        
        
    }
    
    
    /// Is called in the FirebaseController when the listener has type .movies. It notifies the listener of the watchedMovies and moviesToWatch in the database.
    /// - Parameters:
    ///   - change: Of type DatabaseChange which indicates whether something in the database is being updated, removed, or added.
    ///   - moviesWatchedIds: An array of dictionaries that contains the current user's watched movie ids and their reviews.
    ///   - moviesToWatchIds: An array of dictionaries that contains the current user's watched movie ids.
    func onMoviesChange(change: DatabaseChange, moviesWatchedIds: [[String:Any]], moviesToWatchIds: [[String:Any]]) {
        
        // set movieList to the relevant array of movieIds with reviews attached
        // (reviews for movies to watch will return nil since a user can only review movies they have watched)
        if listType == .currentUserToWatch {
            movieList = moviesToWatchIds
            
            // Generate Notification
            guard appDelegate.notificationsEnabled == true else {
                print("Notifications are disabled")
                return
            }
            Task {
                for movie in movieList {

                    // get movie data
                    let movieData = await requestMovieDataById(movieId: movie["movieId"] as! Int)
                    if let movieReleaseDateString = movieData?.release_date, let movieTitle = movieData?.title {
                        let dateFormatter = DateFormatter()
                        dateFormatter.locale = Locale.current
                        dateFormatter.dateFormat = "yyyy-MM-dd"
                        let movieReleaseDate = dateFormatter.date(from:movieReleaseDateString)
                        let currentDate = Date()
                        if currentDate > movieReleaseDate! {
                            let content = UNMutableNotificationContent()
                            content.title = "\(movieTitle) has been released."
                            content.sound = UNNotificationSound.default
                            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 5, repeats: false)
                            let request = UNNotificationRequest(identifier: MovieListTableViewController.NOTIFICATION_IDENTIFIER, content: content, trigger: trigger)
                            
                            // add the request to send the message
                            try await UNUserNotificationCenter.current().add(request)

                        }
                    }

                }
            }
            

            
        }
        else if listType == .currentUserWatched {
           movieList = moviesWatchedIds

        }
        
        else if listType == .publicUserToWatch {
            movieList = selectedUser!.moviesToWatch
        }
        
        else if listType == .publicUserWatched {
            movieList = selectedUser!.moviesWatched
        }
        
        tableView.reloadData()
    }
    
    
    func onAuthChange(change: DatabaseChange, userIsLoggedIn: Bool, error: String) {
        // N/A
    }
    
    func onUsernameAdded(change: DatabaseChange, users: [User]) {
        // N/A
    }
    
    /// Allows the user to save Movie Lists locally to the device.
    @IBAction func downloadList(_ sender: Any) {
        if listType == .currentUserWatched {
            
            do {
                // Code so that userdefault will allow nil review description values
                let data = try NSKeyedArchiver.archivedData(withRootObject: movieList, requiringSecureCoding: false)
                userDefaults.set(data, forKey: "watchedMovies")
                displayMessage(title: "Success", message: "Downloaded Movies to Watch to local storage")

            }
            catch {
                    print("Error")
                }

        }
        else if listType == .currentUserToWatch {
            do {
                // Code so that userdefault will allow nil review description values and scores
                let data = try NSKeyedArchiver.archivedData(withRootObject: movieList, requiringSecureCoding: false)
                userDefaults.set(data, forKey: "toWatchMovies")
                displayMessage(title: "Success", message: "Downloaded Movies to Watch to local storage")

            }
            catch {
                    print("Error")
                }
            
        }
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        // this tableview will only have 1 section
        return 1
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // the number of rows will be the number of movies in the movieList array
        return movieList.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        // Cast cell to type MovieListTableViewCell
        let cell = tableView.dequeueReusableCell(withIdentifier: "watchedMovie", for: indexPath) as! MovieListTableViewCell
        
        let movie = movieList[indexPath.row]
        
        Task {
            do {
                // get the title of the movie by the id and set it the the label's text property
                cell.movieTitleLabel.text = await requestMovieDataById(movieId: movie["movieId"] as! Int)?.title
            }
    
        }
        return cell
    }
    

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: false)
        
        // get the movie and the get the id of that movie as the selectedMovieId
        let movie = movieList[indexPath.row]
        let selectedMovieId = movie["movieId"] as! Int
        
        Task {
            do {
                // set the selected movie to class variable
                selectedMovie = await requestMovieDataById(movieId: selectedMovieId)
                selectedMovieReview = movie
                
                // give the user the option to see the review for a movie only if the listType is current or public UserWatched via an actionsheet
                if listType == .currentUserWatched || listType == .publicUserWatched {
                    let actionSheet = UIAlertController(title: selectedMovie?.title, message: nil, preferredStyle: .actionSheet)
        
                    actionSheet.addAction(UIAlertAction(title: "View Movie Details", style: .default, handler: { [self] action in
                        // show the movie information
                        performSegue(withIdentifier: "showMovieInfoFromList", sender: nil)
                    }))
                    
                    actionSheet.addAction(UIAlertAction(title: "View Review", style: .default, handler: { [self] action in
                        
                        // present the popup of the review by directily intanciating it
                        let storyboard = UIStoryboard(name: "Main", bundle: nil)
                        let vc = storyboard.instantiateViewController(withIdentifier: "ViewReviewViewController") as! ViewReviewViewController
                        vc.currentMovie = selectedMovie
                        vc.currentMovieReview = selectedMovieReview
                        self.present(vc, animated: true)
                        
                    }))
                    
                    // give the option for the user to dismiss the actionsheet
                    actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
                    present(actionSheet, animated: true)
                }
                
                else if listType == .currentUserWatched || listType == .currentUserToWatch {
                    // if the listtype is public or current UserToWatch then perform the segue
                    performSegue(withIdentifier: "showMovieInfoFromList", sender: nil)
                }
                
                else if listType == .downloadedWatched {
                    // present the popup of the review by directily intanciating it
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    let vc = storyboard.instantiateViewController(withIdentifier: "ViewReviewViewController") as! ViewReviewViewController
                    vc.currentMovie = selectedMovie
                    vc.currentMovieReview = selectedMovieReview
                    self.present(vc, animated: true)
                    
                }
                
            }
    
        }
    }
    
    override func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        // the user should only be able to delete items from their own lists.
        if listType == .publicUserWatched || listType == .publicUserToWatch || listType == .downloadedWatched || listType == .downloadedToWatch{
            return false
        }
        
        else {
            return true
        }
        
    }

    override func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        
        // Get movie to be edited
        let movie = movieList[indexPath.row]
        
        
        if editingStyle == .delete {
            
            // Create an actionsheet giving the user the option to permanently delete the movie or move it to the other list
            let actionSheet = UIAlertController(title: "Remove Movie", message: "Are you sure you want to delete this movie?", preferredStyle: .actionSheet)
            actionSheet.addAction(UIAlertAction(title: "Delete Permanently", style: .destructive, handler: { [self] action in
                if listType == .currentUserToWatch {
                    databaseController?.removeMovieToWatchFromUser(movie: movie)
                }
                else if listType == .currentUserWatched {
                    databaseController?.removeMovieWatchedFromUser(movie: movie )
                }
            }))
            
            if listType == .currentUserToWatch {
                actionSheet.addAction(UIAlertAction(title: "Move to Watched Movies", style: .default, handler: { [self] action in
                    databaseController?.removeMovieToWatchFromUser(movie: movie)
                    databaseController?.addMovieWatchedToUser(movie: movie)
                }))
            }
            
            else if listType == .currentUserWatched {
                actionSheet.addAction(UIAlertAction(title: "Move to Movies to Watch", style: .default, handler: { [self] action in
                    databaseController?.removeMovieWatchedFromUser(movie: movie)
                    databaseController?.addMovieToWatchToUser(movieId: movie["movieId"] as! Int)
                }))
                
            }
            
            
            
            actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { action in
                print("Cancel removal of movie")
                
            }))
            
            // show the action sheet
            present(actionSheet, animated: true)
            tableView.reloadData()
        }
    }
    

    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // set the currentMovie variable in the Movie Information View Controller to be the selected movie in the movieList
        if segue.identifier == "showMovieInfoFromList" {
            if let destination = segue.destination as? MovieInformationViewController {
                destination.currentMovie = selectedMovie
                
            }
            
        }
        
        // set the currentMovie and currentMovie variables in the ViewReview View Controller to be the selected movie in the movieList
        if segue.identifier == "showReview" {
            if let destination = segue.destination as? ViewReviewViewController {
                destination.currentMovie = selectedMovie
                destination.currentMovieReview = selectedMovieReview
                
            }
        }
        
            
    }

}
