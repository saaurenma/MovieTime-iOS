//
//  TheatreData.swift
//  MovieTime
//
//  Created by Saauren Mankad on 2/6/2022.
//

import Foundation

/// Data regarding each theatre
class TheaterData : Codable {
    
    let name: String?
    let link: String?
    let address: String?
    let showing: [ShowingData]?
    
}
