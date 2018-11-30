//
//  Constants.swift
//  Chat
//
//  Created by SruthiPattuvakkari on 15/11/18.
//  Copyright © 2018 SruthiPattuvakkari. All rights reserved.
//

import Foundation
import Firebase

struct Constants
{
    struct refs
    {
        static let databaseRoot = Database.database().reference()
        static let databaseChats = databaseRoot.child("chats")
    }
}
