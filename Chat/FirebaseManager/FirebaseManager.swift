//
//  FirebaseManager.swift
//  Chat
//
//  Created by Devashree on 04/12/18.
//  Copyright © 2018 SruthiPattuvakkari. All rights reserved.
//

import Firebase
import FirebaseUI

enum JSONDataType {
    case isBool, isInt, isFloat, isString, isArray, isDictionary, isURL, isNULL
}

enum StorageFileType : String {
    case JPG, PNG, PDF
}

struct StorageFileMetadata {
    var filename:String
    var fullpath:String
    var directory:String
    var contentType:String
    var type:StorageFileType
    var size:Int
    var url:URL?
    var description:String?
}




class FirebaseManager {
    
    //--------------------------------------------------------------------------------
    
    //Mark : Variables / Properties
    
    //--------------------------------------------------------------------------------
    
    static let shared = FirebaseManager()
    
    var currentUserId : String?
    var isLoggedIn : Bool {
        return currentUserId == nil ? true : false
    }
    
    fileprivate(set) var auth:Auth?
    fileprivate(set) var authUI: FUIAuth?
    fileprivate(set) var authStateListenerHandle: AuthStateDidChangeListenerHandle?
    
    var fileCache : [String:Data] = [:]
    var currentUpload : StorageUploadTask? // can monitor, pause, resume the current upload task
    
    //--------------------------------------------------------------------------------
    
    //Mark : Initializers
    
    //--------------------------------------------------------------------------------
    
    fileprivate init() {
        //User listener
        Auth.auth().addStateDidChangeListener { auth, listenerUser in
            if let user = listenerUser {
                print("SIGN IN: \(user.email ?? user.uid)")
                self.currentUserId = user.uid
                
                self.saveUserIfNeeded(user: user)
            } else {
                self.currentUserId = nil
                
                print("SIGN OUT: no user")
            }
        }
        
        handleConnectedUser()
    }
    
    //--------------------------------------------------------------------------------
    
    func handleConnectedUser() {
       
        Constants.FirebaseReferances.connection.observe(.value, with: { snapshot in
            if let connected = snapshot.value as? Bool , connected {
                // internet connected
                // banner alert
            } else {
                // internet disconnected
                // banner alert
            }
        })
    }
    
    func loginWithEmail(vc: UIViewController) {
        self.auth = Auth.auth()
        self.authUI = FUIAuth.defaultAuthUI()
        self.authUI?.delegate = vc as? FUIAuthDelegate
        let authViewController = authUI?.authViewController()
        vc.present(authViewController!, animated: true, completion: nil)
    }
    
    //--------------------------------------------------------------------------------
    
    func logout(completionHandler: @escaping ((_ success:Bool) -> ())) {
        let user = Auth.auth().currentUser
        let onlineRef = Database.database().reference(withPath: "online/\(String(describing: user?.uid))")
        
        onlineRef.removeValue { (error, _) in
            
            if let error = error {
                print("Removing online failed: \(error)")
                completionHandler(false)
                return
            }
            
            do {
                try Auth.auth().signOut()
                completionHandler(true)
            } catch (let error) {
                print("Auth sign out failed: \(error)")
                completionHandler(false)
            }
        }
    }
    
    //--------------------------------------------------------------------------------
    
    //  USER
    
    //--------------------------------------------------------------------------------
    
    func saveUserIfNeeded(user: User) {
        self.userExists(user, completionHandler: { (exists) in
            if(!exists){
                self.newUser(user, completionHandler: nil)
            }
        })
    }
    
    //--------------------------------------------------------------------------------
    
    func getAllUsers(_ completionHandler: @escaping ([DataSnapshot]) -> ()) {
        
        Constants.FirebaseReferances.databaseUsers.observe(.value) { (snapshot) in
            if var child = snapshot.children.allObjects as? [DataSnapshot] {

                child = child.filter {
                    $0.key != self.currentUserId
                }

                completionHandler(child)
            }
        }
    }
    
    //--------------------------------------------------------------------------------
    
    func getCurrentUser(_ completionHandler: @escaping (String, [String:Any]) -> ()) {
        guard let user = Auth.auth().currentUser else{
            return
        }
        
        Constants.FirebaseReferances.databaseUsers.child(user.uid).observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            if let userData = snapshot.value as? [String:Any] {
                completionHandler(user.uid, userData)
            } else{
                print("user has no data")
            }
        }
    }
    
    //--------------------------------------------------------------------------------
    
    func getUser(UID:String, _ completionHandler: @escaping ([String:Any]) -> ()){
        Constants.FirebaseReferances.databaseUsers.child(UID).observeSingleEvent(of: .value, with: { (snapshot) in
            if let userData = snapshot.value as? [String:Any]{
                completionHandler(userData)
            }
        })
    }
    
    //--------------------------------------------------------------------------------
    
    func updateCurrentUserWith(key:String, object value:Any, completionHandler: ((_ success:Bool) -> ())? ) {
        guard let user = Auth.auth().currentUser else{
            if let completion = completionHandler{
                completion(false)
            }
            return
        }
        Constants.FirebaseReferances.databaseUsers.child(user.uid).updateChildValues([key:value]) { (error, ref) in
            if let e = error{
                print(e.localizedDescription)
                if let completion = completionHandler {
                    completion(false)
                }
            } else{
                //                print("saving \(value) into \(key)")
                if let completion = completionHandler{
                    completion(true)
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------------
    
    func newUser(_ user:User, completionHandler: ((_ success:Bool) -> ())? ) {
        var newUser:[String:Any] = [
            "createdAt": Date.init().timeIntervalSince1970
        ]
        // copy user data over from AUTH
        if let nameString  = user.displayName { newUser["name"] = nameString   }
        if let imageURL    = user.photoURL {    newUser["image"] = imageURL    }
        if let emailString = user.email {       newUser["email"] = emailString }
        
        Constants.FirebaseReferances.databaseUsers.child(user.uid).updateChildValues(newUser) { (error, ref) in
            if let e = error{
                print(e.localizedDescription)
                if let completion = completionHandler{
                    completion(false)
                }
            } else{
                if let completion = completionHandler{
                    completion(true)
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------------
    
    func userExists(_ user: User, completionHandler: @escaping (Bool) -> ()) {
        Constants.FirebaseReferances.databaseUsers.child(user.uid).observeSingleEvent(of: .value) { (snapshot: DataSnapshot) in
            if snapshot.value != nil {
                completionHandler(true)
            } else{
                completionHandler(false)
            }
        }
    }
    
    //--------------------------------------------------------------------------------
    
    //  STORAGE
    
    //--------------------------------------------------------------------------------
    
    func imageFromStorageBucket(_ filename: String, completionHandler: @escaping (_ image:UIImage, _ didRequireDownload:Bool) -> ()) {
        if let imageData = fileCache[filename]{
            if let image = UIImage(data: imageData){
                //TODO: check timestamp against database, force a data refresh
                completionHandler(image, false)
                return
            }
        }
        
        
        let imageRef = Constants.FirebaseReferances.storageRef.child(STORAGE_IMAGE_DIR + filename)
        
        imageRef.getData(maxSize: IMG_SIZE_MAX * 1024 * 1024) { (data, error) in
            if let e = error{
                print(e.localizedDescription)
            } else{
                if let imageData = data {
                    if let image = UIImage(data: imageData){
                        self.fileCache[filename] = imageData
                        completionHandler(image, true)
                    } else{
                        print("problem making image out of received data")
                    }
                }
            }
        }
    }
    
    //--------------------------------------------------------------------------------
    
    // specify a UUIDFilename, or it will generate one for you
    func uploadFileAndMakeRecord(_ data:Data, fileType:StorageFileType, description:String?, completionHandler: @escaping (_ metadata:StorageFileMetadata) -> ()) {
        
        // prep file info
        var filename:String = UUID.init().uuidString
        var storageDir:String
        let uploadMetadata = StorageMetadata()
        switch fileType {
        case .JPG:
            filename = filename + ".jpg"
            storageDir = STORAGE_IMAGE_DIR
            uploadMetadata.contentType = "image/jpeg"
        case .PNG:
            filename = filename + ".png"
            storageDir = STORAGE_IMAGE_DIR
            uploadMetadata.contentType = "image/png"
        case .PDF:
            filename = filename + ".pdf"
            storageDir = STORAGE_DOCUMENT_DIR
            uploadMetadata.contentType = "application/pdf"
        }
        let filenameAndPath:String = storageDir + filename
        
        // STEP 1 - upload file to storage
        // TODO: make currentUpload an array, if upload in progress add this to array
        currentUpload = Constants.FirebaseReferances.storageRef.child(filenameAndPath).putData(data, metadata: uploadMetadata, completion: { (metadata, error) in
            if let e = error {
                print(e.localizedDescription)
            } else {
                // upload success, add file to cache
                self.fileCache[filename] = data
                if let meta = metadata {
                    // STEP 2 - record new file in database
                    var entry:[String:Any] = ["filename":filename,
                                              "fullpath":filenameAndPath,
                                              "directory":storageDir,
                                              "content-type":uploadMetadata.contentType ?? "",
                                              "type":fileType.rawValue,
                                              "size":data.count]
                    
                    Constants.FirebaseReferances.storageRef.downloadURL(completion: { (url, error) in
                        entry["url"] = url?.absoluteString
                    })
                        
                        
//                    meta.downloadURL(){
//                        entry["url"] = downloadURL.absoluteString
//                    }
                    if let descriptionString = description{
                        entry["description"] = descriptionString
                    }
                    let key = Constants.FirebaseReferances.database.child("files/" + storageDir).childByAutoId().key
                    Constants.FirebaseReferances.database.child("files/" + storageDir).updateChildValues([key:entry]) { (error, ref) in
                        let info:StorageFileMetadata = StorageFileMetadata(filename: filename, fullpath: filenameAndPath, directory: storageDir, contentType: uploadMetadata.contentType ?? "", type: fileType, size: data.count, url: entry["url"] as! URL, description: description)
                        completionHandler(info)
                    }
                }
            }
        })
    }
}

