//
//  MovieData.swift
//  MovieTime
//
//  Created by Saauren Mankad on 27/4/2022.
//

import Foundation

/// Codable to define a MovieData object which defines the properties of a movie  from TMDB API
class MovieData: Codable {
    
    let id: Int?
    let title: String?
    let poster_path: String?
    let release_date: String?
    let overview: String?
    let backdrop_path: String?
    let status: String?
    let runtime: Int?
    
}
