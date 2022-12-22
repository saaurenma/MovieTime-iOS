//
//  SettingsViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 17/5/2022.
//

import UIKit
import FirebaseAuth

/// A custom View Controller class to define how the SettingsViewController should be handled
class SettingsViewController: UIViewController {
    
    
    @IBOutlet weak var privateModeSwitch: UISwitch!
    
    weak var databaseController: DatabaseProtocol?
    
    
    override func viewDidLoad() {
        // get access to the DatabaseProtocol instance defined in AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        
        super.viewDidLoad()
        
        // set the navigation item title to include the current user's username
        if let username = databaseController?.currentUsername {
            self.navigationItem.title = "Settings: \(username)"
        }
        else {
            self.navigationItem.title = "Settings"
        }
        
        // check the privacy status of the user and update the switch to match it
        if databaseController?.defaultUser?.isPrivate == true {
            
            privateModeSwitch.setOn(true, animated: true)
        }
        else {
            privateModeSwitch.setOn(false, animated: true)
        }
        
    }
    
    
    
    /// If the switch changes to on, then set the current user's privacy to true. If the switch is changed to off, then set the current user's privacy to false.
    /// If a given user has privacy enabled, this means that other users will not be able to view that given user's movie lists.
    /// - Parameter sender: The switch being checked if it is on or not.
    @IBAction func privateSwitchDidChange(_ sender: UISwitch) {
        
        if sender.isOn {
            databaseController?.setUserPrivacy(isPrivate: true)
        }
        else   {
            databaseController?.setUserPrivacy(isPrivate: false)
        }
        
        
    }
    
    
    
    
    /// An action triggered by clicking the 'Sign Out' button. Signs the user out of the application
    @IBAction func signOut(_ sender: Any) {
        
        
        Task {
            do {
                // set the current user to nil
                databaseController?.currentUser = nil
                
                // sign out the user
                try Auth.auth().signOut()
                
                // change the RootViewController to the initial Login ViewController, returning the user to that page
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                let loginNavController = storyboard.instantiateViewController(identifier: "LoginNavigationController")
                (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(loginNavController)
                
            }
            catch {
                print("failed to sign out with error \(error.localizedDescription)")
                
            }
            
            
            
        }
        
    }
    
    /// Clears the downloaded MovieLists of the user
    @IBAction func clearDownloads(_ sender: Any) {
        // set the lists to nil
        UserDefaults.standard.set([], forKey: "toWatchMovies")
        UserDefaults.standard.set([], forKey: "watchedMovies")
        displayMessage(title: "Success", message: "Local copy of lists were deleted.")
    }
    
}
