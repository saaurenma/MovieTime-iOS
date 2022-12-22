//
//  MoviesTableViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 27/4/2022.
//

import UIKit
import SDWebImage

/// Custom Class to define a View Controller that allows the user to search for movies based on their title from TheMovieDB API.
class SearchMoviesTableViewController: UITableViewController, UISearchBarDelegate {
    
    
    let CELL_MOVIE = "movieCell"
    
    // Array that will contain the movies that are retrieved upon searching
    var newMovies = [MovieData]()
    
    // Define indicator
    var indicator = UIActivityIndicatorView()
    
    // Constants for searching
    let MAX_ITEMS_PER_REQUEST = 20
    let MAX_REQUESTS = 10
    
    // Index for searching
    var currentRequestIndex: Int = 0
    
    var selectedMovie: MovieData?
    
    weak var databaseController: DatabaseProtocol?
    
    override func viewDidLoad() {
    
        // Get access to instanciated DatabaseProtocol instanciated in AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        super.viewDidLoad()
                
        
        // Define a search controller and attach it as a navigation item
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchBar.delegate = self
        searchController.obscuresBackgroundDuringPresentation = false
        searchController.searchBar.placeholder = "Search"
        searchController.searchBar.showsCancelButton = false
        navigationItem.searchController = searchController
        // Ensure the search bar is always visible.
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
        
        // Define a loading indicator that will show while movies are being downloaded and add it as a subview
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(indicator)
        
        // Define constraints for loading indicator
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
    }
    
    
    /// When editing of the search bar is complete, it is assumed that the user would like to make a new search query.
    /// - Parameter searchBar: The movie searchbar
    ///
    func searchBarTextDidEndEditing(_ searchBar: UISearchBar) {
        // Delete all previously held movies in newMovies
        newMovies.removeAll()
        tableView.reloadData()
        
        // If the searchbar text is empty do nothing
        guard searchBar.text != nil || searchBar.text == "" else {
            return
        }
        
        let searchText = searchBar.text
        
        navigationItem.searchController?.dismiss(animated: true)
        
        // Display the loading indicator
        indicator.startAnimating()
        
        Task {
            URLSession.shared.invalidateAndCancel()
            currentRequestIndex = 1
            // Pass the searchText to requestMoviesNamed
            await requestMoviesNamed(searchText!)
        }
    }
    
    
    /// Populates the newMovies array with movies that are found based on the search query by the user of movieName from TheMovieDB API.
    /// - Parameter movieName: The name/title of the movie that the user is searching for.
    func requestMoviesNamed(_ movieName: String) async {
        
        // Construct a URL to search for a movie
        var searchURLComponents = URLComponents()
        searchURLComponents.scheme = "https"
        searchURLComponents.host = "api.themoviedb.org"
        searchURLComponents.path = "/3/search/movie"
        searchURLComponents.queryItems = [
            
            URLQueryItem(name: "api_key", value: ""),
            URLQueryItem(name: "language", value: "en-US"),
            // pass the movie name to the URL
            URLQueryItem(name: "query", value: movieName),
            URLQueryItem(name: "page", value: "\(currentRequestIndex)")
            
        ]
        
        // If the URL is invalid exit the function
        guard let requestURL = searchURLComponents.url else {
            return
        }
        
        let urlRequest = URLRequest(url: requestURL)
        
        do {
            
            // Download the search result data
            let  (data, _) = try await URLSession.shared.data(for: urlRequest)
            
            await MainActor.run {
                // Stop the indicator
                indicator.stopAnimating()
            }
            
            // Decode the downloaded data using SearchData Codable
            let decoder = JSONDecoder()
            let popularData = try decoder.decode(SearchData.self, from: data)
            
            if let movies = popularData.results {
                await MainActor.run {
                    // Append the contents of the search result to the newMovies array and reload tableView
                    newMovies.append(contentsOf: movies)
                    tableView.reloadData()
                }
                
                if movies.count == MAX_ITEMS_PER_REQUEST, currentRequestIndex + 1 < MAX_REQUESTS {
                    currentRequestIndex += 1
                    // call the function with the next request page (index)
                    await requestMoviesNamed(movieName)
                }
                
                
            }
            
            
        }
        
        catch let error {
            print(error)
        }
        
    }
    
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // Number of rows will be the number of movies returned by the search
        return newMovies.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        // Cast the cell to SearchMovieTableViewCell and set the label in the cell to he movie title
        let cell = tableView.dequeueReusableCell(withIdentifier: CELL_MOVIE, for: indexPath) as! SearchMovieTableViewCell
        let movie = newMovies[indexPath.row]
        cell.movieTitleLabel.text = movie.title
        
        // Set imageView in the cell to the poster
        let rootUrl = "https://image.tmdb.org/t/p/w185"
        if let posterlink = movie.poster_path {
            cell.moviePosterImageView.sd_setImage(with: URL(string: rootUrl+posterlink))
        }
        else {
            // If a poster is not available, set it to a placeholder
            cell.moviePosterImageView.image = UIImage(named: "backdropPlaceholderImage")
        }
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        // Set the selected movie and segue to movie info
        selectedMovie = newMovies[indexPath.row]
        tableView.deselectRow(at: indexPath, animated: false)
        self.performSegue(withIdentifier: "showMovieInfo", sender: nil)
        
    }
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Set the MovieInformationViewController currentMovie variable as the selectedMovie
        if segue.identifier == "showMovieInfo" {
            if let destination = segue.destination as? MovieInformationViewController {
                destination.currentMovie = selectedMovie
            }
        }
        
    }
    
}
