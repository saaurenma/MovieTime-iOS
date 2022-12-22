//
//  UserTableViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 11/5/2022.
//

import UIKit
import FirebaseFirestore

/// Defines the TableViewController where publci users of the app can be seen and searched through
class UserTableViewController: UITableViewController, DatabaseListener, UISearchResultsUpdating {
    
    // set the listener type to listen for new users
    var listenerType: ListenerType = .users
    
    weak var databaseController: DatabaseProtocol?
    
    // User list and filteredUser list which will hold the search results
    var newUsers: [User] = []
    var filteredUsers: [User] = []
    
    // The user selected from the tableview
    var selectedUser: User?
    
    // The type of list selected
    var selectedListType: MovieListType?
    
    override func viewDidLoad() {
        
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        filteredUsers = newUsers
        
        super.viewDidLoad()
        
        // Setup search controller and add it as a navigation item
        let searchController = UISearchController(searchResultsController: nil)
        searchController.searchResultsUpdater = self
        searchController.searchBar.placeholder = "Search All Users"
        navigationItem.hidesSearchBarWhenScrolling = false
        navigationItem.searchController = searchController
        
    }
    
    /// Updates the search results as the user searches for users by their username.
    /// - Parameter searchController: Username search controller.
    func updateSearchResults(for searchController: UISearchController) {
        
        // If there is no searchtext then exit the function
        guard let searchText = searchController.searchBar.text?.lowercased() else {
            return
        }
        
        if searchText.count > 0 {
            // Filter users by whether their username contains the searchText
            filteredUsers = newUsers.filter({(user:User) -> Bool in return (user.username?.lowercased().contains(searchText) ?? false)
            })
            
        } else {
            filteredUsers = newUsers
        }
        
        tableView.reloadData()
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        // Add the current class to the database controller as a listener when the view appears
        databaseController?.addListener(listener: self)
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Remove the current class to the database controller as a listener when the view disappears
        databaseController?.removeListener(listener: self)
    }
    
    
    func onMoviesChange(change: DatabaseChange, moviesWatchedIds: [[String:Any]], moviesToWatchIds: [[String:Any]]) {
        // N/A
    }
    
    /// Notifies this class if there were any new users added to the application.
    /// - Parameters:
    ///   - change: Of type DatabaseChange which indicates whether something in the database is being updated, removed, or added.
    ///   - users: A list of user objects. Each user has it's privacy status, and lists of movies
    func onUsernameAdded(change: DatabaseChange, users: [User]) {
        
        // Filter out the current user from the array of users
        newUsers = users.filter({(user:User) -> Bool in return (user.id != databaseController?.currentUser?.uid)
        })
        
        updateSearchResults(for: navigationItem.searchController!)
    }
    
    func onAuthChange(change: DatabaseChange, userIsLoggedIn: Bool, error: String) {
        // N/A
    }
    
    // MARK: - Table view data source
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        // The number of users will determine the number of rows
        return filteredUsers.count
        
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "userCell", for: indexPath)
        
        // set cell label to the username of each user
        cell.textLabel?.text = filteredUsers[indexPath.row].username
        
        return cell
    }
    
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: false)
        
        // Save the selected user
        selectedUser = filteredUsers[indexPath.row]
        
        // Provide an option to the user to either View the user's watched movies or to watch movies via an actionsheet
        let actionSheet = UIAlertController(title: "View Movies", message: "\(filteredUsers[indexPath.row].username ?? "")", preferredStyle: .actionSheet)
        
        actionSheet.addAction(UIAlertAction(title: "Watched Movies", style: .default, handler: { [self] action in
            // Save the list type and perform the segue
            selectedListType = .publicUserWatched
            performSegue(withIdentifier: "showPublicUserList", sender: nil)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Movies to Watch", style: .default, handler: { [self] action in
            // Save the list type and perform the segue
            selectedListType = .publicUserToWatch
            performSegue(withIdentifier: "showPublicUserList", sender: nil)
            
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        
        present(actionSheet, animated: true, completion: nil)
        
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Attach the saved listType and selectedUser to MovieListTableViewController
        if segue.identifier == "showPublicUserList" {
            if let destination = segue.destination as? MovieListTableViewController {
                destination.listType = selectedListType
                destination.selectedUser = selectedUser
            }
            
        }
    }
    
}
