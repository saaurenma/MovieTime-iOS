//
//  VideoRequestData.swift
//  MovieTime
//
//  Created by Saauren Mankad on 10/6/2022.
//

import Foundation

/// A list of videos returned by TMDB for a particular movie
class VideoRequestData: Codable {
    let results: [VideoData]?

}
