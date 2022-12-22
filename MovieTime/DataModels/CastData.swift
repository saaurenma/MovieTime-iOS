//
//  CastData.swift
//  MovieTime
//
//  Created by Saauren Mankad on 28/4/2022.
//

import Foundation

/// Codable to define a CastData object which defines the properties of a cast member for a given movie  from TMDB API
class CastData: NSObject, Decodable {
    
    
    let id: Int?
    let cast: [ActorData]?
    let crew: [CrewData]?
}
