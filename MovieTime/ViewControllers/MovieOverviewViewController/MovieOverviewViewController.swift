//
//  MovieOverviewViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 1/6/2022.
//

import UIKit
import SDWebImage

/// Custom ViewController class to define a View Controller that will allow the user to browse movies that are Now Playing, Popular, Top Rated, and Upcoming as per TheMovieDB API
class MovieOverviewViewController: UIViewController, UICollectionViewDelegate, UICollectionViewDataSource  {
    
    // Initialise indexes
    var nowPlayingPageIndex: Int = 1
    var popularPageIndex: Int = 1
    var topRatedPageIndex: Int = 1
    var upcomingPageIndex: Int = 1
    
    let MAX_ITEMS_PER_REQUEST = 20
    let MAX_REQUESTS = 10
    
    // Outlets for collection views
    @IBOutlet weak var nowPlayingCollectionView: UICollectionView!
    @IBOutlet weak var popularCollectionView: UICollectionView!
    @IBOutlet weak var topRatedCollectionView: UICollectionView!
    @IBOutlet weak var upcomingCollectionView: UICollectionView!
    
    // Initialise arrays for each movie category
    var nowPlayingMovies = [MovieData]()
    var popularMovies = [MovieData]()
    var topRatedMovies = [MovieData]()
    var upcomingMovies = [MovieData]()
    
    // movie selected
    var selectedMovie: MovieData?
    
    override func viewDidLoad() {
        Task {
            // Call all functions to populate collection views
            await requestNowPlayingMovies()
            await requestPopularMovies()
            await requestTopRatedMovies()
            await requestUpcomingMovies()
        }
        
        super.viewDidLoad()
        
        
        // Set delegates and data sources for collection views to the current class
        nowPlayingCollectionView.delegate = self
        popularCollectionView.delegate = self
        topRatedCollectionView.delegate = self
        upcomingCollectionView.delegate = self
        
        nowPlayingCollectionView.dataSource = self
        popularCollectionView.dataSource = self
        topRatedCollectionView.dataSource = self
        upcomingCollectionView.dataSource = self
        
        
        // Format collection views to have rounded corners
        nowPlayingCollectionView.layer.cornerRadius = 12
        popularCollectionView.layer.cornerRadius = 12
        topRatedCollectionView.layer.cornerRadius = 12
        upcomingCollectionView.layer.cornerRadius = 12
        
        
    }
    
    
    
    /// Populates the nowPlayingMovies array with movies that are within the "Now Playing" category on TheMovieDB
    func requestNowPlayingMovies() async {
        
        // Construct a URL to get movies
        var movieURLComponents = URLComponents()
        movieURLComponents.scheme = "https"
        movieURLComponents.host = "api.themoviedb.org"
        movieURLComponents.path = "/3/movie/now_playing"
        movieURLComponents.queryItems = [
            
            URLQueryItem(name: "api_key", value: ""),
            URLQueryItem(name: "language", value: "en-US"),
            // pass current page index to url
            URLQueryItem(name: "page", value: "\(nowPlayingPageIndex)"),
            URLQueryItem(name: "region", value: "AU")
            
            
        ]
        
        // If the URL is invalid exit the function
        guard let requestURL = movieURLComponents.url else {
            return
        }
        
        let urlRequest = URLRequest(url: requestURL)
        
        do {
            // Download the list of movies
            let  (data, _) = try await URLSession.shared.data(for: urlRequest)
            
            // Use JSONDecoder and SearchData to decode the downloaded movie list
            let decoder = JSONDecoder()
            let movieData = try decoder.decode(SearchData.self, from: data)
            
            if let movies = movieData.results {
                await MainActor.run {
                    // Append to the array and reload collection view
                    nowPlayingMovies.append(contentsOf: movies)
                    nowPlayingCollectionView.reloadData()
                }
                
                if movies.count == MAX_ITEMS_PER_REQUEST, nowPlayingPageIndex + 1 < MAX_REQUESTS {
                    // Call the array with an incremented page index value
                    nowPlayingPageIndex += 1
                    await requestNowPlayingMovies()
                }
                
                
            }
            
        }
        
        catch let error {
            print(error)
        }
        
        
    }
    
    /// Populates the popularMovies array with movies that are within the "Popular" category on TheMovieDB
    func requestPopularMovies() async {
        
        // Construct a URL to get movies
        var movieURLComponents = URLComponents()
        movieURLComponents.scheme = "https"
        movieURLComponents.host = "api.themoviedb.org"
        movieURLComponents.path = "/3/movie/popular"
        
        movieURLComponents.queryItems = [
            
            URLQueryItem(name: "api_key", value: ""),
            URLQueryItem(name: "language", value: "en-US"),
            // pass current page index to url
            URLQueryItem(name: "page", value: "\(popularPageIndex)"),
            URLQueryItem(name: "region", value: "AU")
            
        ]

        guard let requestURL = movieURLComponents.url else {
            return
        }
        
        let urlRequest = URLRequest(url: requestURL)
        
        do {
            // Download the list of movies
            let  (data, _) = try await URLSession.shared.data(for: urlRequest)
            
            // Use JSONDecoder and SearchData to decode the downloaded movie list
            let decoder = JSONDecoder()
            let movieData = try decoder.decode(SearchData.self, from: data)
            
            if let movies = movieData.results {
                await MainActor.run {
                    // Append to the array and reload collection view
                    popularMovies.append(contentsOf: movies)
                    popularCollectionView.reloadData()
                }
                
                if movies.count == MAX_ITEMS_PER_REQUEST, popularPageIndex + 1 < MAX_REQUESTS {
                    // Call the array with an incremented page index value

                    popularPageIndex += 1
                    await requestPopularMovies()
                }
            }
            
        }
        
        catch let error {
            print(error)
        }
        
        
    }
    
    
    func requestTopRatedMovies() async {
        
        // Construct a URL to get movies
        var movieURLComponents = URLComponents()
        movieURLComponents.scheme = "https"
        movieURLComponents.host = "api.themoviedb.org"
        movieURLComponents.path = "/3/movie/top_rated"
        
        movieURLComponents.queryItems = [
            
            URLQueryItem(name: "api_key", value: ""),
            URLQueryItem(name: "language", value: "en-US"),
            // pass current page index to url
            URLQueryItem(name: "page", value: "\(topRatedPageIndex)"),
            URLQueryItem(name: "region", value: "AU")
            
            
        ]

        // If the URL is invalid exit the function
        guard let requestURL = movieURLComponents.url else {
            return
        }
        
        let urlRequest = URLRequest(url: requestURL)
        
        do {
            // Download the list of movies
            let  (data, _) = try await URLSession.shared.data(for: urlRequest)
            
            // Use JSONDecoder and SearchData to decode the downloaded movie list
            let decoder = JSONDecoder()
            let movieData = try decoder.decode(SearchData.self, from: data)
            
            if let movies = movieData.results {
                await MainActor.run {
                    // Append to the array and reload collection view
                    topRatedMovies.append(contentsOf: movies)
                    topRatedCollectionView.reloadData()
                }
                
                if movies.count == MAX_ITEMS_PER_REQUEST, topRatedPageIndex + 1 < MAX_REQUESTS {
                    // Call the array with an incremented page index value
                    topRatedPageIndex += 1
                    await requestTopRatedMovies()
                }
            }
            
        }
        
        catch let error {
            print("error: ")
            print(error)
        }
        
        
    }
    
    
    func requestUpcomingMovies() async {
        
        // Construct a URL to get movies
        var movieURLComponents = URLComponents()
        movieURLComponents.scheme = "https"
        movieURLComponents.host = "api.themoviedb.org"
        movieURLComponents.path = "/3/movie/upcoming"
        
        movieURLComponents.queryItems = [
            
            URLQueryItem(name: "api_key", value: ""),
            URLQueryItem(name: "language", value: "en-US"),
            // pass current page index to url
            URLQueryItem(name: "page", value: "\(upcomingPageIndex)"),
            URLQueryItem(name: "region", value: "AU")

        ]
        

        // If the URL is invalid exit the function
        guard let requestURL = movieURLComponents.url else {
            return
        }
        
        let urlRequest = URLRequest(url: requestURL)
        
        do {
            // Download the list of movies
            let  (data, _) = try await URLSession.shared.data(for: urlRequest)
            
            // Use JSONDecoder and SearchData to decode the downloaded movie list
            let decoder = JSONDecoder()
            let movieData = try decoder.decode(SearchData.self, from: data)
            
            if let movies = movieData.results {
                await MainActor.run {
                    // Append to the array and reload collection view
                    upcomingMovies.append(contentsOf: movies)
                    upcomingCollectionView.reloadData()
                }
                
                if movies.count == MAX_ITEMS_PER_REQUEST, upcomingPageIndex + 1 < MAX_REQUESTS {
                    // Call the array with an incremented page index value
                    upcomingPageIndex += 1
                    print("upcoming page index -> \(upcomingPageIndex)")
                    await requestUpcomingMovies()
                }
            }
            
        }
        
        catch let error {
            print(error)
        }
        
        
    }
    
    
    
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        
        // Return the appropriate number of movies for each collectionView based on the array count
        if collectionView == self.nowPlayingCollectionView {
            return nowPlayingMovies.count
        }
        
        else if collectionView == self.popularCollectionView {
            return popularMovies.count
        }
        
        else if collectionView == self.topRatedCollectionView {
            return topRatedMovies.count
        }
        
        else if collectionView == self.upcomingCollectionView {
            return upcomingMovies.count
        }
        
        return 0
    }
    
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        
        
        let imageRootURL = "https://image.tmdb.org/t/p/w154"
        
        // Set each cell for each collectionView
        if collectionView == self.nowPlayingCollectionView {
            
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "nowPlayingCell", for: indexPath) as! MovieOverviewCollectionViewCell
            let movie = nowPlayingMovies[indexPath.row]
            
            // Set the title in the cell
            cell.movieTitleLabel.text = movie.title
            
            // Set the poster in the cell or set a backdrop if a poster is not available
            if let moviePosterPath = movie.poster_path {
                cell.movieImageView.sd_setImage(with: URL(string: imageRootURL+moviePosterPath))
                
            }
            else {
                cell.movieImageView.image = UIImage(named: "backdropPlaceholderImage")
            }
            
            // Format the cell
            cell.layer.borderColor = UIColor.systemGray6.cgColor
            cell.layer.borderWidth = 5
            cell.layer.cornerRadius = 12
            cell.layer.backgroundColor = UIColor(named: "collectionViewColour")?.cgColor
            
            return cell
        }
        
        else if collectionView == self.popularCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "popularCell", for: indexPath) as! MovieOverviewCollectionViewCell
            let movie = popularMovies[indexPath.row]
            cell.movieTitleLabel.text = movie.title
            
            if let moviePosterPath = movie.poster_path {
                cell.movieImageView.sd_setImage(with: URL(string: imageRootURL+moviePosterPath))
            }
            else {
                cell.movieImageView.image = UIImage(named: "backdropPlaceholderImage")
            }
            
            cell.layer.borderColor = UIColor.systemGray6.cgColor
            cell.layer.borderWidth = 5
            cell.layer.cornerRadius = 12
            cell.layer.backgroundColor = UIColor(named: "collectionViewColour")?.cgColor
            
            return cell
        }
        
        else if collectionView == self.topRatedCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "topRatedCell", for: indexPath) as! MovieOverviewCollectionViewCell
            let movie = topRatedMovies[indexPath.row]
            cell.movieTitleLabel.text = movie.title
            
            if let moviePosterPath = movie.poster_path {
                cell.movieImageView.sd_setImage(with: URL(string: imageRootURL+moviePosterPath))
                
            }
            else {
                cell.movieImageView.image = UIImage(named: "backdropPlaceholderImage")
            }
            
            cell.layer.borderColor = UIColor.systemGray6.cgColor
            cell.layer.borderWidth = 5
            cell.layer.cornerRadius = 12
            cell.layer.backgroundColor = UIColor(named: "collectionViewColour")?.cgColor
            
            return cell
        }
        
        else if collectionView == self.upcomingCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "upcomingCell", for: indexPath) as! MovieOverviewCollectionViewCell
            let movie = upcomingMovies[indexPath.row]
            cell.movieTitleLabel.text = movie.title
            
            if let moviePosterPath = movie.poster_path {
                cell.movieImageView.sd_setImage(with: URL(string: imageRootURL+moviePosterPath))
                
            }
            
            else {
                cell.movieImageView.image = UIImage(named: "backdropPlaceholderImage")
            }
            
            cell.layer.borderColor = UIColor.systemGray6.cgColor
            cell.layer.borderWidth = 5
            cell.layer.cornerRadius = 12
            cell.layer.backgroundColor = UIColor(named: "collectionViewColour")?.cgColor
            
            return cell
        }
        
        
        
        return UICollectionViewCell()
        
        
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        // set the selected movie depending on which collectionview it was selected in
        if collectionView == self.nowPlayingCollectionView {
            selectedMovie = nowPlayingMovies[indexPath.row]
        }
        
        else if collectionView == self.popularCollectionView {
            selectedMovie = popularMovies[indexPath.row]
            
        }
        
        else if collectionView == self.topRatedCollectionView {
            selectedMovie = topRatedMovies[indexPath.row]
            
        }
        
        else if collectionView == self.upcomingCollectionView {
            selectedMovie = upcomingMovies[indexPath.row]
            
        }
        
        // perform the segue to show information about the selectedMovie
        performSegue(withIdentifier: "showMovieInfoFromOverview", sender: nil)

    }
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Set the currentMovie in MovieInformationViewController as the selected movie
        if segue.identifier == "showMovieInfoFromOverview" {
            if let destination = segue.destination as? MovieInformationViewController {
                destination.currentMovie = selectedMovie
            }
            
        }
        
    }
    
}
