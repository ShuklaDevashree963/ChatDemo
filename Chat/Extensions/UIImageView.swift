//
//  UIImageView.swift
//  Chat
//
//  Created by Devashree on 04/12/18.
//  Copyright © 2018 SruthiPattuvakkari. All rights reserved.
//

import Foundation

let STORAGE_IMAGE_DIR : String = "images/"
let STORAGE_DOCUMENT_DIR : String = "documents/"
let IMG_SIZE_MAX:Int64 = 15

extension UIImageView {
    
    public func imageFromStorage(_ filename: String){
        if let imageData = FirebaseManager.shared.fileCache[filename] {
            if let image = UIImage(data: imageData){
                self.image = image
                return
            }
        }
        
        let imageRef = Constants.FirebaseReferances.storageRef.child("images/" + filename)
        imageRef.getData(maxSize: IMG_SIZE_MAX * 1024 * 1024) { (data, error) in
            if let e = error {
                print(e.localizedDescription)
            } else{
                if let imageData = data {
                    if let image = UIImage(data: imageData){
                        FirebaseManager.shared.fileCache[filename] = imageData
                        self.image = image
                    }
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------------
    
    public func profileImageForUser(uid: String){
        FirebaseManager.shared.getUser(UID: uid) { (userData) in
            if let imageFilename = userData["image"] as? String{
                if let imageData = FirebaseManager.shared.fileCache[imageFilename]{
                    if let image = UIImage(data: imageData){
                        self.image = image
                        return
                    }
                }
                
                let imageRef = Constants.FirebaseReferances.storageRef.child("images/" + imageFilename)
                imageRef.getData(maxSize: IMG_SIZE_MAX * 1024 * 1024) { (data, error) in
                    if let e = error{
                        print(e.localizedDescription)
                    } else{
                        if let imageData = data {
                            if let image = UIImage(data: imageData){
                                FirebaseManager.shared.fileCache[imageFilename] = imageData
                                self.image = image
                            }
                        }
                    }
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------------
    
    public func imageFromUrl(_ urlString: String) {
        if let url = URL(string: urlString) {
            let request:URLRequest = URLRequest(url: url)
            let session:URLSession = URLSession.shared
            let task = session.dataTask(with: request, completionHandler: {data, response, error -> Void in
                DispatchQueue.main.async {
                    if let imageData = data as Data? {
                        self.image = UIImage(data: imageData)
                    }
                }
            })
            task.resume()
        }
    }
    
}
