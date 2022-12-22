//
//  FirebaseController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 5/5/2022.
//

import Foundation
import Firebase
import FirebaseFirestoreSwift
import FirebaseAuth

/// Implements DatabaseProtocol and defines interaction between the application and the Firestore and FirebaseAuth systems
class FirebaseController: NSObject, DatabaseProtocol {
    
    var authController: Auth
    
    var database: Firestore
    var userLoginStatus: Bool
    var currentUser: FirebaseAuth.User?
    
    var moviesRef: CollectionReference?
    
    var defaultUser: User?
    
    var currentUsername: String = ""
    
    var listeners = MulticastDelegate<DatabaseListener>()
    
    var users: [User]?
    
    override init() {
        
        // Initialise variables and firebase
        FirebaseApp.configure()
        authController = Auth.auth()
        database = Firestore.firestore()
        userLoginStatus = false
        defaultUser = User()
        users = []
        super.init()
    }
    
    
    func cleanup() {
        print("cleanup")
    }
    
    /// Adds a listener (class) to the MulticastDelegate
    /// - Parameter listener: The class that registers as a listener
    func addListener(listener: DatabaseListener) {
        
        listeners.addDelegate(listener)
        
        if listener.listenerType == .auth || listener.listenerType == .all {
            listener.onAuthChange(change: .update, userIsLoggedIn: userLoginStatus, error: "")
        }
        
        if listener.listenerType == .movies || listener.listenerType == .all {
            listener.onMoviesChange(change: .update, moviesWatchedIds: defaultUser!.moviesWatched, moviesToWatchIds: defaultUser!.moviesToWatch)
        }
        
        if listener.listenerType == .users || listener.listenerType == .all {
            listener.onUsernameAdded(change: .update, users: users!)
        }
        
    }
    
    /// Removes the class as a listener
    /// - Parameter listener: The class to be removed as a listener
    func removeListener(listener: DatabaseListener) {
        listeners.removeDelegate(listener)
        
    }
    
    
    /// Logs in a user into Firebase with a given email and password
    /// - Parameters:
    ///   - email: The email address of the user of type string
    ///   - password: The password of the user of type string
    func logInUser(email: String, password: String) {
        Task {
            do {
                // Attempt sign in
                let authDataResult = try await authController.signIn(withEmail: email, password: password)
                // If sign in success, save current user
                currentUser = authDataResult.user
                // Load document reference of the current user
                let docRef = database.collection("users").document(currentUser!.uid)
                docRef.getDocument{ [self] (document, error) in
                    if let document = document {
                        // set properties as set by user
                        let data = document.data()
                        currentUsername = data!["username"]! as? String ?? ""
                        defaultUser?.isPrivate = data!["isPrivate"] as? Bool
                    }
                }
                
                // invoke auth listeners and pass true to indicate successful sign in
                listeners.invoke { (listener) in
                    if listener.listenerType == ListenerType.auth ||
                        listener.listenerType == ListenerType.all {
                        listener.onAuthChange(change:.update, userIsLoggedIn: true, error: "")
                        
                    }
                    
                }
                
                // setup listeners
                self.setupMoviesListener()
                self.setupUsernamesListener()
            }
            catch {
                // sign in failed
                userLoginStatus = false
                // pass false to onAuthChange
                listeners.invoke { (listener) in
                    if listener.listenerType == ListenerType.auth ||
                        listener.listenerType == ListenerType.all {
                        listener.onAuthChange(change:.update, userIsLoggedIn: false, error: String(describing: error.localizedDescription))
                    }
                }
            }
            
            
            
        }
    }
    
    /// Creates a user in Firebase
    /// - Parameters:
    ///   - newEmail: The new  email address of type string
    ///   - newPassword: The new password of type string
    ///   - newUsername: The new username of type string
    func createUser(newEmail: String, newPassword: String, newUsername: String) {
        
        Task {
            do {
                // If a username is not provided throw an error
                if newUsername.trimmingCharacters(in: .whitespacesAndNewlines) == "" {
                    throw "A username must be provided"
                }
                
                // Attempt to create a user with Firebase and set the currentUser and currentUsername
                let authDataResult = try await authController.createUser(withEmail: newEmail, password: newPassword)
                currentUser = authDataResult.user
                currentUsername = newUsername
                // Create a new document for the new user with their chosen username and empty arrays for movies
                try await database.collection("users").document(currentUser!.uid).setData([
                    "username": newUsername,
                    "moviesWatched" : [],
                    "moviesToWatch" : [],
                    "isPrivate" : false
                ])
                
                defaultUser?.username = newUsername
                
                // Invoke listeners
                listeners.invoke { (listener) in
                    if listener.listenerType == ListenerType.auth ||
                        listener.listenerType == ListenerType.all {
                        // Pass true to onAuthChange since sign up was successful
                        listener.onAuthChange(change:.update, userIsLoggedIn: true, error: "")
                    }
                    
                }
                
                // Setup listeners
                self.setupMoviesListener()
                self.setupUsernamesListener()
            }
            
            catch {
                // sign up failed
                userLoginStatus = false
                listeners.invoke { (listener) in
                    if listener.listenerType == ListenerType.auth ||
                        listener.listenerType == ListenerType.all {
                        listener.onAuthChange(change:.update, userIsLoggedIn: false, error: String(describing: error.localizedDescription))
                    }
                }
                
            }
            
        }
    }
    
    
    /// Signs a user out of Firebase
    func signOutUser() {
        Task {
            do {
                // Attempt to sign the user out
                try authController.signOut()
                
                // Pass false to onAuthChange since the user is logged out
                listeners.invoke { (listener) in
                    if listener.listenerType == ListenerType.auth ||
                        listener.listenerType == ListenerType.all {
                        listener.onAuthChange(change:.update, userIsLoggedIn: false, error: "")
                        // sign out success
                        
                    }
                    
                }
                
                
            }
            catch {
                print("failed to sign out with error \(error.localizedDescription)")
                
            }
            
            
            
        }
    }
    
    /// Sets up listener for usernames
    func setupUsernamesListener() {
        
        moviesRef = database.collection("users")
        
        // Get documents from database collection
        moviesRef!.getDocuments() {
            
            (querySnapshot, error) in
            
            guard let querySnapshot = querySnapshot else {
                print("Failed to get data for this user --> \(error!)")
                return
            }
            
            // pass document snapshot to function
            self.parseUsernamesSnapshot(snapshot: querySnapshot)
        }
        
        
    }
    
    
    /// Parses the snapshot to create an array of User objects
    /// - Parameter snapshot: The snapshot of the documents provided by setupUsernamesListener
    func parseUsernamesSnapshot(snapshot: QuerySnapshot) {
        
        users = []
        
        
        for document in snapshot.documents {
            
            let newUser = User()
            // set user id
            newUser.id = document.documentID
            
            // set username and privacy status
            newUser.username = document.data()["username"] as? String
            newUser.isPrivate = document.data()["isPrivate"] as? Bool
            
            // Only get append the data of a user that is not private
            if newUser.isPrivate == false {
                
                let watchedMovies = (document.data()["moviesWatched"] as? [[String:Any]])!
                let toWatchMovies = (document.data()["moviesToWatch"] as? [[String:Any]])!
                
                // append movies to watch and movies watched
                for movie in toWatchMovies {
                    newUser.moviesToWatch.append(movie)
                }
                
                for movie in watchedMovies {
                    newUser.moviesWatched.append(movie)
                }
                
                // add the user to the array
                users?.append(newUser)
            }
            
        }
        
        listeners.invoke { (listener) in
            // pass the array of users to onUsernameAdded
            if listener.listenerType == ListenerType.users || listener.listenerType == ListenerType.all {
                listener.onUsernameAdded(change: .update, users: users!)
            }
            
        }
    }
    
    /// Sets up the Movie list listener
    func setupMoviesListener() {
        moviesRef = database.collection("users")
        // Get snapshot for current user
        moviesRef!.document(currentUser!.uid).addSnapshotListener{
            (querySnapshot, error) in
            
            guard let querySnapshot = querySnapshot else {
                print("Failed to get data for this user --> \(error!)")
                return
            }
            // pass snapshot for current user to parseMoviesSnapshot
            self.parseMoviesSnapshot(snapshot: querySnapshot)
        }
        
    }
    
    /// Parses the current user snapshot to create a list of movies watched and movies to watch for the current user.
    /// - Parameter snapshot: The snapshot of the current user passed by setupMoviesListener.
    func parseMoviesSnapshot(snapshot: DocumentSnapshot) {
        
        defaultUser = User()
        // Set the id and username for the default user
        defaultUser?.id = snapshot.documentID
        defaultUser?.username = currentUsername
        
        // If the snapshot is nil then exit the function
        if snapshot.data() == nil {
            return
        }
        
        // Append watchedMovies and toWatchMovies to the user
        if let watchedMovies = snapshot.data()!["moviesWatched"] as? [[String : Any]], let toWatchMovies = snapshot.data()!["moviesToWatch"] as? [[String : Any]] {
            for movie in watchedMovies {
                defaultUser?.moviesWatched.append(movie)
            }
            
            for movie in toWatchMovies {
                defaultUser?.moviesToWatch.append(movie)
            }
        }
        
        
        // once the arrays have been created update the onMoviesChange listener.
        listeners.invoke { (listener) in
            if listener.listenerType == ListenerType.movies || listener.listenerType == ListenerType.all {
                listener.onMoviesChange(change: .update, moviesWatchedIds: defaultUser!.moviesWatched, moviesToWatchIds: defaultUser!.moviesToWatch)
            }
            
        }
    }
    
    /// Allows a watched movie to be added to the current user.
    /// - Parameter movie: An object with the movieId, reviewScore and reviewDescription.
    /// - Returns: True if the addition was successful false if it was not.
    func addMovieWatchedToUser(movie: [String:Any]) -> Bool {
        
        // check for duplciates and exit function if the movie is already in the users list
        let movieId = movie["movieId"] as! Int
        let currentMovieIdArray = defaultUser?.moviesWatched.map{ movie in
            
            movie["movieId"] ?? ""
            
        }
        if currentMovieIdArray?.contains(where: {$0 as! Int == movieId}) == true {
            return false
        }
        
        
        Task {
            do {
                // Add movie to array in Firestore
                try await database.collection("users").document(currentUser!.uid).updateData([
                    "moviesWatched" : FieldValue.arrayUnion([movie])
                ])
                
            }
            
            catch {
                print("Failed to add watched movie")
                
            }
        }
        
        return true
    }
    
    
    
    /// Allows a movie to watch to be added to the current user.
    /// - Parameter movieId: The movieId of the movie that needs to be added.
    /// - Returns: True if the addition was successful false if it was not.
    func addMovieToWatchToUser(movieId: Int) -> Bool {
        
        // check for duplciates and exit function if the movie is already in the users list
        let currentMovieIdArray = defaultUser?.moviesToWatch.map{ movie in
            
            movie["movieId"] ?? ""
            
        }
        if currentMovieIdArray?.contains(where: {$0 as! Int == movieId}) == true {
            return false
        }
        
        Task {
            do {
                // review score and description will be nil since movies to watch do not have reviews appended to them
                let toWatchMovieMap = ["movieId" : movieId, "reviewScore": nil, "reviewDescription": nil] as [String : Any]
                
                // Add the movie to the moviesToWatch array in Firestore
                try await database.collection("users").document(currentUser!.uid).updateData([
                    "moviesToWatch" : FieldValue.arrayUnion([toWatchMovieMap]),
                ])
            }
            
            catch {
                print("Failed to add movie to watch")
            }
        }
        
        
        
        return true
        
    }
    
    /// Removes a watched movie from the current user.
    /// - Parameter movie: The movie object to be deleted from Firestore.
    func removeMovieWatchedFromUser(movie: [String:Any]) {
        
        Task {
            do {
                // Remove the movie from Firestore
                try await database.collection("users").document(currentUser!.uid).updateData([
                    "moviesWatched" : FieldValue.arrayRemove([movie])
                ])
            }
            
            catch {
                
            }
        }
        
    }
    
    /// Removes a movieToWatch from the current user.
    /// - Parameter movie: The movie object to be deleted from Firestore.
    func removeMovieToWatchFromUser(movie: [String:Any]) {
        
        Task {
            do {
                // Remove the movie from Firestore
                try await database.collection("users").document(currentUser!.uid).updateData([
                    "moviesToWatch" : FieldValue.arrayRemove([movie]),
                ])
            }
            
            catch {
                
            }
        }
        
    }
    
    
    /// Sets the users privacy. If the user is private, other users cannot see their movie lists.
    /// - Parameter isPrivate: True if the user wants to be private, false if the user wants to be public.
    func setUserPrivacy(isPrivate: Bool) {
        
        Task {
            do {
                // Set the isPrivate variable in the current user's document
                try await database.collection("users").document(currentUser!.uid).updateData([
                    "isPrivate" : isPrivate,
                ])
                defaultUser?.isPrivate = isPrivate
            }
            
            catch {
                print("Failed to change privacy setting")
                
            }
        }
        
        
    }
    
    
    
}
