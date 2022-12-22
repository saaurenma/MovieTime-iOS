//
//  ShowtimeData.swift
//  MovieTime
//
//  Created by Saauren Mankad on 2/6/2022.
//

import Foundation

/// Scraped data for each Showtime
class ShowtimeData: Codable {
    
    let day: String?    
    let date: String?
    let theaters: [TheaterData]?
}
