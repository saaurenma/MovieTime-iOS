//
//  CrewData.swift
//  MovieTime
//
//  Created by Saauren Mankad on 28/4/2022.
//

import Foundation

/// Codable to define a CrewData object which defines the properties of an Crew member for a given movie  from TMDB API
class CrewData: Codable {
    let id: Int?
    let name: String?
    let job: String?
}
