//
//  ActorData.swift
//  MovieTime
//
//  Created by Saauren Mankad on 28/4/2022.
//

import Foundation

/// Cordable to define a ActorData object which defines the properties of an Actor for a given movie  from TMDB API
class ActorData: Codable {
    
    let id: Int?
    let name: String?
    let character: String?
    let profile_path: String?
}
