//
//  UsersListVC.swift
//  Chat
//
//  Created by Devashree on 30/11/18.
//  Copyright © 2018 SruthiPattuvakkari. All rights reserved.
//

import UIKit
import Firebase
import FirebaseUI

protocol DownloadChatsForUser {
    func downloadChats(receiverId : String)
}

class UsersListVC: UITableViewController {

    //--------------------------------------------------------------------------------
    
    //Mark : IBOutlets
    
    //--------------------------------------------------------------------------------
    
    @IBOutlet weak var btnLogin: UIBarButtonItem!
    
    //--------------------------------------------------------------------------------
    
    //Mark : Variables / Properties
    
    //--------------------------------------------------------------------------------
    
    var delegate : DownloadChatsForUser?
    
    var userList : [DataSnapshot] = [] {
        didSet {
            tableView.reloadData()
        }
    }
    
    var receiverId = "" {
        didSet {
            delegate?.downloadChats(receiverId: self.receiverId)
        }
    }
    
    //--------------------------------------------------------------------------------
    
    //Mark : UIViewController methods
    
    //--------------------------------------------------------------------------------
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.clearsSelectionOnViewWillAppear = false
       
    
        if FirebaseManager.shared.isLoggedIn {
            updateUIForLogout()
        } else {
            updateUIForLogin()
        }
    }
    
    //--------------------------------------------------------------------------------
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if FirebaseManager.shared.isLoggedIn {
            getUserList()
        }
    }
    
    //--------------------------------------------------------------------------------
    
    //Mark : Factory methods
    
    //--------------------------------------------------------------------------------
    
    func viewcontroller() -> UsersListVC {
        return StoryboardConstants.usersListVC as! UsersListVC
    }
    
    //--------------------------------------------------------------------------------
    
    //Mark : Navigation related
    
    //--------------------------------------------------------------------------------
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
      
    }
    
    //--------------------------------------------------------------------------------
    
    //Mark : IBActions
    
    //--------------------------------------------------------------------------------
    
    @IBAction func btnLoginClicked(_ sender: UIBarButtonItem) {
        if sender.title == "Login" {
            FirebaseManager.shared.loginWithEmail(vc: self)
        } else {
            FirebaseManager.shared.logout { (isSuccess) in
                if isSuccess {
                    self.updateUIForLogout()
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------------
    
    //Mark : Custom methods
    
    //--------------------------------------------------------------------------------
    
    func updateUIForLogin() {
        btnLogin.title = "Logout"
        title = Auth.auth().currentUser?.displayName
    }
    
    //--------------------------------------------------------------------------------
    
    func updateUIForLogout() {
        btnLogin.title = "Login"
        title = "Chat"
        userList.removeAll()
    }
    
    //--------------------------------------------------------------------------------
    
    func getUserList() {
        FirebaseManager.shared.getAllUsers { (users) in
            self.userList = users
        }
    }
}

//--------------------------------------------------------------------------------

//Mark : Extension - FUIAuthDelegate

//--------------------------------------------------------------------------------

extension UsersListVC : FUIAuthDelegate {
    
    func authUI(_ authUI: FUIAuth, didSignInWith user: User?, error: Error?) {
        guard let authError = error else {
            FirebaseManager.shared.newUser(user!) { (isSuccess) in
                
            }
            updateUIForLogin()
            getUserList()
            return
        }
        
        let errorCode = UInt((authError as NSError).code)
        
        switch errorCode {
        case FUIAuthErrorCode.userCancelledSignIn.rawValue:
            print("User cancelled sign-in");
            break
            
        default:
            let detailedError = (authError as NSError).userInfo[NSUnderlyingErrorKey] ?? authError
            print("Login error: \((detailedError as! NSError).localizedDescription)");
        }
    }
}

//--------------------------------------------------------------------------------

//Mark : Extension - Table view

//--------------------------------------------------------------------------------

extension UsersListVC {
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    //--------------------------------------------------------------------------------
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userList.count == 0 ? 1 : userList.count
    }
    
    //--------------------------------------------------------------------------------
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "chatCell", for: indexPath)
        if userList.count == 0 {
            cell.textLabel?.text = "No users"
        } else {
            cell.textLabel?.text = (userList[indexPath.row].value as! [String: Any])["name"] as? String
        }
        return cell
    }
    
    //--------------------------------------------------------------------------------
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        (self.splitViewController?.viewControllers[1] as! ChatViewController).receiverUser = userList[indexPath.row]
    }
}

//let storyboard = UIStoryboard(name: "Main", bundle: nil)
//let viewController = storyboard.instantiateViewController(withIdentifier: "main") as! ChatViewController
//let navController = UINavigationController(rootViewController: viewController)
//
//navController.view.backgroundColor = UIColor.white
////navController.navigationController?.isNavigationBarHidden = false
//navController.modalPresentationStyle = UIModalPresentationStyle.popover
//navController.popoverPresentationController?.permittedArrowDirections =  UIPopoverArrowDirection.up
//
//navController.preferredContentSize = CGSize(width: 455, height: 700)
//
//let popPresentCnt = navController.popoverPresentationController
//popPresentCnt?.sourceView = sender
//popPresentCnt?.sourceRect = sender.bounds
//popPresentCnt?.backgroundColor = UIColor.white
//present(navController, animated: true,completion: nil)
