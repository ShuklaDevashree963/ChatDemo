//
//  Constants.swift
//  Chat
//
//  Created by SruthiPattuvakkari on 15/11/18.
//  Copyright © 2018 SruthiPattuvakkari. All rights reserved.
//

import Foundation
import Firebase

struct Ids {
    static let usersListVCId = "UsersListVC"
    static let chatVCId = "ChatViewController"
}

struct StoryboardConstants {
    
    static let mainStoryboard = UIStoryboard(name: "Main", bundle: nil)
    static let usersListVC = mainStoryboard.instantiateViewController(withIdentifier: Ids.usersListVCId)
    static let chatVC = mainStoryboard.instantiateViewController(withIdentifier: Ids.chatVCId)
    
}

struct Constants {
    struct FirebaseReferances {
        static let databaseRoot = Database.database().reference()
        static let database = Database.database().reference().root
        static let databaseChats = databaseRoot.child("chats")
        static let databaseUsers = databaseRoot.child("users")
        
        static let connection = Database.database().reference(withPath: ".info/connected")
        
        static let storageRef = Storage.storage().reference()
    }
}
