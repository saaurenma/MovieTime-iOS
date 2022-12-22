//
//  DatabaseProtocol.swift
//  MovieTime
//
//  Created by Saauren Mankad on 5/5/2022.
//

import Foundation
import Firebase


/// Describes whether something in the database is being updated, removed, or added.
enum DatabaseChange {
    
    case add
    case remove
    case update
    
}


/// The type of listener being used by the ViewController.
/// - all: All listeners.
/// - users: Used by classes that want to listen for new users added to the system.
/// - movies: Used by classes that want to listen for new movies being added to watched and to watch lists.
/// - auth: Used by classes that want to listen to the authentication state of the current user.
enum ListenerType {
    case all
    case users
    case movies
    case auth
}

/// A protocol that can be implemented by classes that want to implement any of the following methods.
/// - onMoviesChange: Implemented by classes which have the listenerType movies
/// - onUsernameAdded: Implemented by classes which have the listenerType users
/// - onAuthChange: Implemented by classes which have the listenerType auth
protocol DatabaseListener: AnyObject {
    var listenerType: ListenerType{get set}
    func onMoviesChange(change: DatabaseChange, moviesWatchedIds: [[String:Any]], moviesToWatchIds: [[String:Any]])
    func onUsernameAdded(change:DatabaseChange, users: [User])
    func onAuthChange(change: DatabaseChange, userIsLoggedIn: Bool, error:String)
    
}

/// Database Protocol that will be implemented by FirebaseController and the methods of which will be accessed by ViewControllers that would like to interact with the database
protocol DatabaseProtocol: AnyObject {
    var currentUsername: String{get set}
    var currentUser: FirebaseAuth.User?{get set}
    var defaultUser: User? {get set}

    func cleanup()
    func addListener(listener: DatabaseListener)
    func removeListener(listener: DatabaseListener)

    func addMovieWatchedToUser(movie: [String:Any]) -> Bool
    func addMovieToWatchToUser(movieId: Int) -> Bool
    func removeMovieWatchedFromUser(movie: [String:Any])
    func removeMovieToWatchFromUser(movie: [String:Any])
    func setUserPrivacy(isPrivate: Bool)
    
    
    func logInUser(email: String, password: String)
    func createUser(newEmail: String, newPassword: String, newUsername: String)
    func signOutUser()
}
