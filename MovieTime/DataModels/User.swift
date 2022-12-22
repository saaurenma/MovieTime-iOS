//
//  User.swift
//  MovieTime
//
//  Created by Saauren Mankad on 11/5/2022.
//

import Foundation

/// Object to store user properties
class User: NSObject {
    
    var id: String?
    var username: String?
    var isPrivate: Bool?
    var moviesWatched : [[String:Any]] = []
    var moviesToWatch: [[String:Any]] = []

}
