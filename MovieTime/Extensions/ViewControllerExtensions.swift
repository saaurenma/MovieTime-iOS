//
//  ViewControllerExtensions.swift
//  MovieTime
//
//  Created by Saauren Mankad on 9/6/2022.
//

import Foundation
import UIKit

extension UIViewController {
    
    /// Displays a UIAlertController to the user with a given title and message.
    /// - Parameters:
    ///   - title: The title of the Alert of type String
    ///   - message: The message of the Alert of type String.
    func displayMessage(title: String, message: String) {
        Task {
            do {
                let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
                alertController.addAction(UIAlertAction(title: "Dismiss", style: .default,handler: nil ))
                self.present(alertController, animated: true, completion: nil)
            }
        }
    }
    
    /// Fetches movie Information based on the provided movieId from TheMovieDB API
    /// - Parameter movieId: The movie Id number defined in the theMovieDB database of type Integer.
    /// - Returns: The relevant data for the movie.
    func requestMovieDataById(movieId: Int) async -> MovieData? {
        
        // Construct url of where the movie is located in TheMovieDB API.
        var titleURLComponents = URLComponents()
        titleURLComponents.scheme = "https"
        titleURLComponents.host = "api.themoviedb.org"
        
        // pass movieId to the URL
        titleURLComponents.path = "/3/movie/" + "\(movieId)"
        titleURLComponents.queryItems = [
            
            URLQueryItem(name: "api_key", value: ""),
            URLQueryItem(name: "language", value: "en-US"),
        ]
        
        
        guard let requestURL = titleURLComponents.url else {
            return nil
        }
        
        let urlRequest = URLRequest(url: requestURL)
        
        
        do {
            // download the data
            let  (data, _) = try await URLSession.shared.data(for: urlRequest)
            let decoder = JSONDecoder()
            
            // decode the data using the JSONDecoder and the MovieData codable
            let movieData = try decoder.decode(MovieData.self, from:data)
            
            return movieData
            
        }
        
        catch let error {
            print(error)
        }
        return nil
    }
}
