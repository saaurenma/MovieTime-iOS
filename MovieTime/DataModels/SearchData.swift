//
//  PopularData.swift
//  MovieTime
//
//  Created by Saauren Mankad on 27/4/2022.
//

import Foundation

/// Data structure to store search results for movies from TMDB API
class SearchData: NSObject, Decodable {
    
    let results: [MovieData]?
    let total_pages: Int?
    let page: Int?
    let total_results: Int?
    
    
    
}
