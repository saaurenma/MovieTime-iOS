//
//  TabBarViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 1/6/2022.
//

import UIKit

/// Custom class for the primary TabBarController that is used for this application.
/// This class's primary purpose is to attach the correct listType variable to the MovieListTableViewController when the user chooses the relevant option in the tabbar.
class TabBarController: UITabBarController, UITabBarControllerDelegate {

    override func viewDidLoad() {
        super.viewDidLoad()
        self.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Get array of View Controllers within the Tabbar Controller
        let viewControllers = self.viewControllers
        
        // If there is a NavigationController for Watched movies at index 1 in the array of view controllers, set the listType in MovieListTableViewController
        if let watchedNavController = viewControllers?[1] as? WatchedNavigationController, let movieListTableViewController = watchedNavController.topViewController as? MovieListTableViewController {
            movieListTableViewController.listType = .currentUserWatched
        }
        
        // If there is a NavigationController for Movies to Watch at index 2 in the array of view controllers, set the listType in MovieListTableViewController
        if let toWatchNavigationController = viewControllers?[2] as? ToWatchNavigationController, let movieListTableViewController = toWatchNavigationController.topViewController as? MovieListTableViewController {
            movieListTableViewController.listType = .currentUserToWatch
        }

    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }
    
}
