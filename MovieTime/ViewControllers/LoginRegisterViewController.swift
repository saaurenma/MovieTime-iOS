//
//  LoginRegisterViewController.swift
//  MovieTime
//
//  Created by Saauren Mankad on 5/5/2022.
//

import UIKit
import Firebase
import FirebaseAuth


/// Custom View Controller class which defines the logic for a user logging into the application and creating an account for the application
class LoginRegisterViewController: UIViewController, DatabaseListener {
    
    var listenerType: ListenerType = .auth
    
    // Outlet for relevant textfields
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var usernameTextField: UITextField!
    
    // Define databaseController used to interact with the Firebase database
    weak var databaseController: DatabaseProtocol?
    
    // Initialise UserDefaults
    let defaults = UserDefaults.standard
    
    override func viewDidLoad() {
        
        passwordTextField.isSecureTextEntry = true
        passwordTextField.autocorrectionType = .no
        
        // Get access to DatabaseProtocol instance in AppDelegate
        let appDelegate = UIApplication.shared.delegate as? AppDelegate
        databaseController = appDelegate?.databaseController
        super.viewDidLoad()
        
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Add the class as a listener to the databaseController when the screen appears
        databaseController?.addListener(listener: self)
        
        // If an email was saved to UserDefaults then reload it into the email Text Field.
        if let prevEmail = defaults.string(forKey: "userEmail") {
            emailTextField.text = prevEmail
        }
        
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        // Removes the class as a listener to the databaseController when the screen dissapears
        databaseController?.removeListener(listener: self)
    }
    
    
    /// This function listens to the authentication state of the user and switches to the tabbar controller if the user is logged in or displays an error if the login/register failed.
    /// - Parameters:
    ///   - change: Of type DatabaseChange which indicates whether something in the database is being updated, removed, or added.
    ///   - userIsLoggedIn: FirebaseController passes true to this parameter if the user is logged in, else passes false.
    ///   - error: FirebaseController passes any errors that arise to this function.
    func onAuthChange(change: DatabaseChange, userIsLoggedIn: Bool, error: String) {
        
        // If there is an error passed to this function, display it to the user.
        if error != "" {
            displayMessage(title: "Error", message: error)
            
        }
        
        print("USER LOGIN STATUS -- \(userIsLoggedIn)")
        
        Auth.auth().addStateDidChangeListener{ auth,user in
            
            // if the user is logged in, change the RootViewController to the TabBarController so that the user is able to see it
            if let user = user {
                if userIsLoggedIn == true {
                    print("user signed in as \(user.email!)")
                    let storyboard = UIStoryboard(name: "Main", bundle: nil)
                    // Instanciate the tabbar controller
                    
                    let mainTabBarController = storyboard.instantiateViewController(identifier: "MainTabBarController")
                    (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.changeRootViewController(mainTabBarController)
                    
                }
            }
            
        }
    }
    
    
    func onUsernameAdded(change: DatabaseChange, users: [User]) {
        // N/A
    }
    
    func onMoviesChange(change: DatabaseChange, moviesWatchedIds: [[String:Any]], moviesToWatchIds: [[String:Any]]) {
        // N/A
    }
    
    
    
    /// An action that logs in a user to the application when the login button is tapped
    @IBAction func logInUser(_ sender: Any) {
        
        let email = emailTextField.text
        let password = passwordTextField.text
        
        
        if let email = email, let password = password {
            // call the login user method in the databaseController and save the email entered to UserDefaults
            databaseController?.logInUser(email: email, password: password)
            defaults.set(email, forKey: "userEmail")
        }
        
    }
    
    /// An action that registers the user into the application when the sign up button is tapped
    @IBAction func signUpUser(_ sender: Any) {
        
        let username = usernameTextField.text
        let email = emailTextField.text
        let password = passwordTextField.text
        
        if let email = email, let password = password, let username = username {
            // call the create user method in the databaseController and save the email entered to UserDefaults
            databaseController?.createUser(newEmail: email, newPassword: password, newUsername: username)
            defaults.set(email, forKey: "userEmail")
            
        }
    }
    
    /// An action that resets the user's password when the reset password button is tapped
    @IBAction func resetPassword(_ sender: Any) {
        
        let email = emailTextField.text
        
        if let email = email {
            Task {
                do {
                    // send password reset email to the provided email and display message if it is successful
                    try await Auth.auth().sendPasswordReset(withEmail: email)
                    self.displayMessage(title: "Reset Password", message: "Password reset link sent to \(email)")
                    
                }
                catch {
                    // display message if the password reset was not successful
                    self.displayMessage(title: "Error", message: "\(error.localizedDescription)")
                    
                }
                
                
            }
        }
        
    }
    
}
