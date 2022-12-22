//
//  ShowtimeSearch.swift
//  MovieTime
//
//  Created by Saauren Mankad on 2/6/2022.
//

import Foundation
/// Data returned by SerpAPI once showtimes have been found
class ShowtimeSearch: Codable {
    
    let showtimes: [ShowtimeData]?
}
