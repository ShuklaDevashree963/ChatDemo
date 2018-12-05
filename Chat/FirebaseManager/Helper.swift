//
//  Helper.swift
//  Chat
//
//  Created by Devashree on 30/11/18.
//  Copyright © 2018 SruthiPattuvakkari. All rights reserved.
//

import UIKit
import FirebaseDatabase

struct OnlineOfflineService {
    static func online(for uid: String, status: Bool, success: @escaping (Bool) -> Void) {
        //True == Online, False == Offline
        let onlinesRef = Database.database().reference().child(uid).child("isOnline")
        onlinesRef.setValue(status) {(error, _ ) in
            
            if let error = error {
                assertionFailure(error.localizedDescription)
                success(false)
            }
            success(true)
        }
    }
    
    static func getOnlineUsers() {
        let connectedRef = Database.database().reference(withPath: ".info/connected")
        connectedRef.observe(.value, with: { snapshot in
            if snapshot.value as? Bool ?? false {
                print("Connected")
            } else {
                print("Not connected")
            }
        })
    }
}

