//
//  ShowtimesTableViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 6/6/2022.
//

import UIKit
import CoreLocation

/// Custom Table View Controller class to define a Table View Controller that will display the cinema showtimes near the user's location for a given movie.
class ShowtimesTableViewController: UITableViewController, CLLocationManagerDelegate  {
    
    var allShowtimes = [ShowtimeData]()
    var currentMovie: MovieData?
    
    private var locationManager: CLLocationManager!
    private var currentLocation: CLLocation?
    
    let geocoder = CLGeocoder()
    
    var indicator = UIActivityIndicatorView()
    
    // The selected cinema's address
    var selectedAddress: String?
    var selectedCinema: String?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // initialise LocationManager
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        
        // request location permission
        if CLLocationManager.locationServicesEnabled() {
            locationManager.requestWhenInUseAuthorization()
            locationManager.startUpdatingLocation()
        }
        
        // define loading indicator and add it to the subview of the view controller
        indicator.style = UIActivityIndicatorView.Style.large
        indicator.translatesAutoresizingMaskIntoConstraints = false
        self.view.addSubview(indicator)
        
        // set constraints for the indicator
        NSLayoutConstraint.activate([
            indicator.centerXAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerXAnchor),
            indicator.centerYAnchor.constraint(equalTo: view.safeAreaLayoutGuide.centerYAnchor)
        ])
        
        if let currentMovieTitle = currentMovie?.title {
            self.navigationItem.title = "Times: \(currentMovieTitle)"

        }
    }
    
    
    
    /// From a given location, fetch the city and the country.
    /// Code adapted from : https://stackoverflow.com/questions/44031257/find-city-name-and-country-from-latitude-and-longitude-in-swift
    /// - Parameters:
    ///   - location: The location of which the city and the country is required.
    func fetchCityAndCountry(from location: CLLocation, completion: @escaping (_ city: String?, _ country:  String?, _ error: Error?) -> ()) {
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            completion(placemarks?.first?.locality,
                       placemarks?.first?.country,
                       error)
        }
    }
    
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        defer { currentLocation = locations.last }
        
        // fetch the user's current location, extract the city and country, and fetch showtimes based on those parameters.
        if currentLocation == nil {
            
            if let userLocation = locations.last {
                
                
                fetchCityAndCountry(from: userLocation, completion: { [self] city, country, error in
                    guard let city = city, let country = country, error == nil else { return }
                    indicator.startAnimating()
                    
                    Task {
                        // get showtimes for a particular movie title based on the user's city and country
                        await requestShowtimes(movieName: (currentMovie?.title)!, city: city, country: country)
                        
                        if allShowtimes.count == 0 {
                            displayMessage(title: "Error", message: "No showtimes found near you.")
                        }
                    }
                })
                
                
            }
            
            
            
        }
    }
    
    
    /// Populates the allShowtimes array with showtimes using SerpAPI.
    /// - Parameters:
    ///   - movieName: The title of the movie for which showtimes are required.
    ///   - city: The city location of which the movie showtimes are required.
    ///   - country: The country location of which the movie showtimes are required.
    func requestShowtimes(movieName: String, city: String, country: String) async {
        
        // Construct showtime URL
        var showtimeURLComponents = URLComponents()
        showtimeURLComponents.scheme = "https"
        showtimeURLComponents.host = "serpapi.com"
        showtimeURLComponents.path = "/search.json"
        showtimeURLComponents.queryItems = [
            // pass the movieName, City and Country to the API
            URLQueryItem(name: "q", value: "\(movieName)+Cinemas+\(city)+\(country)"),
            URLQueryItem(name: "hl", value: "en"),
            URLQueryItem(name: "api_key", value: "")
        ]
        
        // if the constructed URL is invalid exit the function
        guard let requestURL = showtimeURLComponents.url else {
            print("Invalid URL.")
            return
        }
        
        let urlRequest = URLRequest(url: requestURL)
        
        do {
            // Download showtime data
            let  (data, _) = try await URLSession.shared.data(for: urlRequest)
            
            await MainActor.run {
                // stop the indicator once data has been downloaded
                indicator.stopAnimating()
            }
            
            let decoder = JSONDecoder()
            
            // Bind the downloaded showtime data with the ShowtimeSearch Codable
            let showtimeSearchResults = try decoder.decode(ShowtimeSearch.self, from: data)
            if let showtimes = showtimeSearchResults.showtimes{
                await MainActor.run {
                    // append the showtimes to the array and reload the tableview
                    allShowtimes.append(contentsOf: showtimes)
                    tableView.reloadData()
                }
            }
        }
        
        catch let error {
            print("error: ")
            print(error)
        }
        
        
    }
    
    
    // MARK: - Table view data source
    
    /// Tells the tableview the number of sections to be displayed. In this case, it will be the number of Dates recieved from the API.
    /// - Parameter tableView: The tableView object requesting this information.
    /// - Returns: The count of allShowtimes.
    override func numberOfSections(in tableView: UITableView) -> Int {
        print("SHOWTIME COUNT")
        print(allShowtimes.count)
        return allShowtimes.count
    }
    
    /// Returns the title for each section in the tableView.
    /// - Parameters:
    ///   - tableView:The tableView object requesting this information.
    ///   - section:  An index number identifying a section in tableView.
    /// - Returns: A string of the day and date of the section.
    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        
        var dayAndDate: String?
        
        if let day = allShowtimes[section].day, let date =  allShowtimes[section].date {
            
            dayAndDate = "\(day), \(date)"
            
        }
        
        return dayAndDate
    }
    
    /// Returns the number of rows that should appear in each section. Since each section is defined as a Date, the number of rows will be defined as the number of cinemas that are showing the movie on that given Date.
    /// - Parameters:
    ///   - tableView:The tableView object requesting this information.
    ///   - section: An index number identifying a section in tableView. In this case, it refers to the index of the Date.
    /// - Returns: The number of theatres showing the movie on that given Day/Date (section).
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return allShowtimes[section].theaters?.count ?? 0
    }
    
    
    
    /// Cell for row at method defines the properties of each cell. Things like setting the cinema name in each cell and times for each cinema are handled here.
    /// - Parameters:
    ///   - tableView: The current tableview object requesting the cell.
    ///   - indexPath: An index path locating a row in tableView.
    /// - Returns: A cell of type ShowtimeTableViewCell.
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath : IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "showtimeCell", for: indexPath) as! ShowtimeTableViewCell
        
        let cinema = allShowtimes[indexPath.section].theaters?[indexPath.row]
        
        cell.currentTheatre = cinema?.name
        cell.currentMovieTitle = currentMovie?.title
        cell.currentMovieRuntime = currentMovie?.runtime
        cell.currentMovieShowtimeDate = allShowtimes[indexPath.section].date!
        cell.showtimeParentViewController = self
        cell.currentTheatreAddress = cinema?.address
        
        cell.cinemaNameLabel.text = cinema?.name
        
        
        // sets a property in the custom cell class named ShowtimeTableViewCell to allow the CollectionView to be populated for each row.
        cell.showings = (allShowtimes[indexPath.section].theaters?[indexPath.row].showing)!
        
        
        return cell
    }
    
    
    // MARK: - Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Set the currentMovie in MovieInformationViewController as the selected movie
        if segue.identifier == "showCinemaLocation" {
            if let destination = segue.destination as? CinemaLocationViewController {
                destination.currentAddress = selectedAddress
                destination.currentLocation = currentLocation
                destination.currentCinema = selectedCinema
            }
            
        }
        
    }
    
    
    
    
    
}
