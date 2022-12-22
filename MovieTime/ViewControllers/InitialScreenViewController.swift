//
//  InitialScreenViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 10/6/2022.
//

import UIKit

class InitialScreenViewController: UIViewController {
    
    var downloadedWatchedMovies: [[String:Any]] = []
    var downloadedToWatchMovies: [[String:Any]] = []
    var listType: MovieListType?
    
    
    @IBOutlet weak var localListsButton: UIButton!
    
    override func viewDidLoad() {
        
        // Get the lists from user defaults
        if let data = UserDefaults.standard.object(forKey: "watchedMovies") as? Data {
            do {
                downloadedWatchedMovies = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [[String:Any]] ?? []
            }
            catch {
                print("Error")
            }
        }
        else {
            downloadedWatchedMovies = []
            
        }
        
        
        if let data = UserDefaults.standard.object(forKey: "toWatchMovies") as? Data {
            do {
                downloadedToWatchMovies = try NSKeyedUnarchiver.unarchiveTopLevelObjectWithData(data) as? [[String:Any]] ?? []
            }
            catch {
                print("Error")
            }
        }
        else {
            downloadedToWatchMovies = []
        }
        
        
        // If there are not any lists saved disable the button
        if downloadedWatchedMovies.count == 0 && downloadedToWatchMovies.count == 0 {
            localListsButton.isEnabled = false
        }
        else {
            localListsButton.isEnabled = true
        }
        
        super.viewDidLoad()
        
        
    }
    
    /// Allows the user to view locally downloaded movie lists
    @IBAction func viewLocalLists(_ sender: Any) {
        
        let actionSheet = UIAlertController(title: "View Local Movie List", message: "Internet is still required to see the posters of each movie and titles.", preferredStyle: .actionSheet)
        
        // pass the array and listtype to the tableview controller based on user selection
        actionSheet.addAction(UIAlertAction(title: "View Watched Movies", style: .default, handler: { [self] action in
            listType = .downloadedWatched
            performSegue(withIdentifier: "viewDownloadedLists", sender: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "View Movies To Watch", style: .default, handler: { [self] action in
            listType = .downloadedToWatch
            performSegue(withIdentifier: "viewDownloadedLists", sender: nil)
        }))
        
        actionSheet.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        present(actionSheet, animated: true)
    }
    
    
    // MARK: - Navigation
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "viewDownloadedLists" {
            // set MovieListTableViewController variables to display downloaded lists before segue
            if let destination = segue.destination as? MovieListTableViewController {
                if listType == .downloadedWatched {
                    destination.listType = .downloadedWatched
                    destination.movieList = downloadedWatchedMovies
                }
                else if listType == .downloadedToWatch {
                    destination.listType = .downloadedToWatch
                    destination.movieList = downloadedToWatchMovies
                }
            }
        }
        
    }
    
}
