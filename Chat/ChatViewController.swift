//
//  ViewController.swift
//  Chat
//
//  Created by SruthiPattuvakkari on 15/11/18.
//  Copyright © 2018 SruthiPattuvakkari. All rights reserved.
//

import UIKit
import JSQMessagesViewController
import MobileCoreServices
import Firebase

class ChatViewController: JSQMessagesViewController,UIImagePickerControllerDelegate,UINavigationControllerDelegate {
    
    var messages = [JSQMessage]()
    
    lazy var outgoingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }()
    
    lazy var incomingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let defaults = UserDefaults.standard
        
        if  let id = defaults.string(forKey: "jsq_id"),
            let name = defaults.string(forKey: "jsq_name")
        {
            senderId = id
            senderDisplayName = name
        }
        else
        {
            senderId = String(arc4random_uniform(999999))
            senderDisplayName = ""
            
            defaults.set(senderId, forKey: "jsq_id")
            defaults.synchronize()
            
            showDisplayNameDialog()
        }
        
        title = "Chat: \(senderDisplayName!)"
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(showDisplayNameDialog))
        tapGesture.numberOfTapsRequired = 1
        
        navigationController?.navigationBar.addGestureRecognizer(tapGesture)
        self.view.backgroundColor = UIColor.red
        
        let smilyButton = UIButton()
        smilyButton.setImage(#imageLiteral(resourceName: "Smiley"), for: UIControlState.normal)
        let attachmentButton = UIButton()
        attachmentButton.setImage(#imageLiteral(resourceName: "Attachment"), for: UIControlState.normal)
        
        inputToolbar.contentView.leftBarButtonItem = smilyButton
        inputToolbar.contentView.attachmentButtonItem = attachmentButton
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 40, height: 40)
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 40, height: 40)
        
       

        //.queryOrdered(byChild: "firstname") timestamp
        Constants.refs.databaseChats.observeSingleEvent(of: .value) {
            (snapshot) in
            for _ in snapshot.children.allObjects as! [DataSnapshot] {
                let value = snapshot.value as? NSDictionary
                let firstname = value?["name"] as? String ?? ""
                print(firstname)
            }
        }
        
        
        
        let query = Constants.refs.databaseChats.queryLimited(toLast: 10)
        
        _ = query.observe(.childAdded, with: { [weak self] snapshot in
            
            if let data = snapshot.value as? [String:AnyObject], let id  = data["sender_id"] as? String, let senderName = data["name"] as? String {
            
                if let imageUrl = data["imageUrl"] as? String, imageUrl.count > 0 {
                    var img: UIImage!
                    let mediaItem = JSQPhotoMediaItem(image: nil)
                    mediaItem?.appliesMediaViewMaskAsOutgoing = (id == self?.senderId)
                    mediaItem?.image = nil

                    let ref = Storage.storage().reference(forURL: imageUrl)
                    let megaByte = Int64(1 * 1024 * 1024)

                    ref.getData(maxSize: megaByte) { data, error in
                        guard let imageData = data else {
                            return
                        }
                        img = UIImage(data: imageData)

                        if img != nil{
                            mediaItem?.image = img! as UIImage
                        }

                    }
                    
                    self?.messages.append(JSQMessage(senderId: id, displayName: senderName, media: mediaItem))
                    
                } else if let text = data["text"] as? String {
                    self?.messages.append(JSQMessage(senderId: id, displayName: senderName, text: text))
                }
                
                self?.finishReceivingMessage()
            }
            
//            if let data = snapshot.value as? [String:String], let id  = data["sender_id"] , let senderName = data["name"] , let text = data["text"] {
//
//                let msg : JSQMessage?
//
//                if let imageUrl = data["imageUrl"] , imageUrl.count > 0 {
//                    var img: UIImage!
//                    let mediaItem = JSQPhotoMediaItem(image: nil)
//                    mediaItem?.appliesMediaViewMaskAsOutgoing = (id == self?.senderId)
//                    mediaItem?.image = nil
//
//                    let ref = Storage.storage().reference(forURL: imageUrl)
//                    let megaByte = Int64(1 * 1024 * 1024)
//
//                    ref.getData(maxSize: megaByte) { data, error in
//                        guard let imageData = data else {
//                            return
//                        }
//                        img = UIImage(data: imageData)
//
//                        if img != nil{
//                            mediaItem?.image = img! as UIImage
//                            //self.collectionView!.reloadData()
//                        }
//
//                    }
//                    //
//                    msg = JSQMessage(senderId: id, displayName: senderName, media: mediaItem)
//                } else {
//                    msg = JSQMessage(senderId: id, displayName: senderName, text: text)
//                }
//
//                self?.messages.append(msg!)
//                self?.finishReceivingMessage()
//            }
            
        })
        
       // self.downloadMessages()
    }
    
    @objc func showDisplayNameDialog()
    {
        let defaults = UserDefaults.standard
        
        let alert = UIAlertController(title: "Your Display Name", message: "Before you can chat, please choose a display name. Others will see this name when you send chat messages. You can change your display name again by tapping the navigation bar.", preferredStyle: .alert)
        
        alert.addTextField { textField in
            
            if let name = defaults.string(forKey: "jsq_name")
            {
                textField.text = name
            }
            else
            {
                let names = ["Ford", "Arthur", "Zaphod", "Trillian", "Slartibartfast", "Humma Kavula", "Deep Thought"]
                textField.text = names[Int(arc4random_uniform(UInt32(names.count)))]
            }
        }
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { [weak self, weak alert] _ in
            
            if let textField = alert?.textFields?[0], !textField.text!.isEmpty {
                
                self?.senderDisplayName = textField.text
                
                self?.title = "Chat: \(self!.senderDisplayName!)"
                
                defaults.set(textField.text, forKey: "jsq_name")
                defaults.synchronize()
            }
        }))
        
        present(alert, animated: true, completion: nil)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData!
    {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int
    {
        return messages.count
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageBubbleImageDataForItemAt indexPath: IndexPath!) -> JSQMessageBubbleImageDataSource!
    {
        return messages[indexPath.item].senderId == senderId ? outgoingBubble : incomingBubble
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, avatarImageDataForItemAt indexPath: IndexPath!) -> JSQMessageAvatarImageDataSource!
    {
        if messages[indexPath.item].senderId == senderId {
            return JSQMessagesAvatarImageFactory.avatarImage(withPlaceholder: #imageLiteral(resourceName: "female user"), diameter: 25)
        }else {
            return JSQMessagesAvatarImageFactory.avatarImage(withPlaceholder: #imageLiteral(resourceName: "user 1"), diameter: 25)
        }
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForMessageBubbleTopLabelAt indexPath: IndexPath!) -> NSAttributedString!
    {
        return messages[indexPath.item].senderId == senderId ? nil : NSAttributedString(string: messages[indexPath.item].senderDisplayName)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, attributedTextForCellTopLabelAt indexPath: IndexPath!) -> NSAttributedString!
    {
        return NSAttributedString(string: messages[indexPath.item].date.description)
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForMessageBubbleTopLabelAt indexPath: IndexPath!) -> CGFloat
    {
        return messages[indexPath.item].senderId == senderId ? 0 : 15
    }
    
    override func collectionView(_ collectionView: JSQMessagesCollectionView!, layout collectionViewLayout: JSQMessagesCollectionViewFlowLayout!, heightForCellTopLabelAt indexPath: IndexPath!) -> CGFloat
    {
        return 25
    }
    
    override func didPressSend(_ button: UIButton!, withMessageText text: String!, senderId: String!, senderDisplayName: String!, date: Date!)
    {
        let ref = Constants.refs.databaseChats.childByAutoId()
        
        let message = ["sender_id": senderId, "name": senderDisplayName, "text": text]/*"timestamp": [".sv":"timestamp"]] as [String : Any]*/
        
        ref.setValue(message)
        
        finishSendingMessage()
    }
    
    override func didPressAccessoryButton(_ sender: UIButton!) {
        inputToolbar.contentView.textView.becomeFirstResponder()
        inputToolbar.contentView.rightBarButtonItem.isEnabled = true
        inputToolbar.contentView.textView.text = ""
    }
    
    override func didPressAttachmentButton(_ sender: UIButton!) {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.allowsEditing = true
        present(imagePickerController, animated: true, completion: nil)
        
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker:UIImage?
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage{
            selectedImageFromPicker = editedImage
        }else if let originalImage = info["UIImagePickerControllerOriginalImage"] as? UIImage{
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            let mediaItem = JSQPhotoMediaItem(image: nil)
            mediaItem?.appliesMediaViewMaskAsOutgoing = true
            mediaItem?.image = UIImage(data: UIImageJPEGRepresentation(selectedImage, 0.5)!)
//            let sendMessage = JSQMessage(senderId: senderId, displayName: senderDisplayName, media: mediaItem)
//            self.messages.append(sendMessage!)
            uploadFirebaseStorageUsingImage(image: selectedImage)
        }
        
        dismiss(animated: true, completion: nil)
    }
    
    private func uploadFirebaseStorageUsingImage(image: UIImage) {
        let imageName = NSUUID().uuidString
        let ref = Storage.storage().reference().child("message_images").child(imageName)
        if let uploadData = UIImageJPEGRepresentation(image, 0.2){
            ref.putData(uploadData, metadata: nil, completion: { (metadata, error) in
                if error != nil {
                    print("failed to upload image",error)
                    return
                }
                
                ref.downloadURL { url, error in
                    if let error = error {
                        print(error)
                    } else {
                        if let imageURL = url?.absoluteString {
                            print(imageURL)
                            self.sendImage(imageUrl: imageURL)
                        }
                    }
                }
                
            })
        }
    }
    
    private func sendImage(imageUrl: String){
        let ref = Constants.refs.databaseChats.childByAutoId()
        let messageObject = [
            "text":" ",
            "sender_id":senderId,
            "name": senderDisplayName,
            "imageUrl":imageUrl,
            "timestamp": [".sv":"timestamp"]
            ] as [String:Any]
        ref.setValue(messageObject)
        finishSendingMessage()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func downloadMessages() {
        
        let downloadRef = Constants.refs.databaseChats.queryLimited(toLast: 10)
        
        _ = downloadRef.observe(.childAdded, with: { snapshot in
            if let data = snapshot.value as? [String:AnyObject],
                let id  = data["sender_id"] as? String,
                let senderName = data["name"],
                let imageUrl = data["imageUrl"] as? String {
                
                var img: UIImage!
                let mediaItem = JSQPhotoMediaItem(image: nil)
                mediaItem?.appliesMediaViewMaskAsOutgoing = (id == self.senderId)
                mediaItem?.image = nil
                
                let ref = Storage.storage().reference(forURL: imageUrl)
                let megaByte = Int64(1 * 1024 * 1024)
                
                ref.getData(maxSize: megaByte) { data, error in
                    guard let imageData = data else {
                        return
                    }
                    img = UIImage(data: imageData)
                    
                    if img != nil{
                        mediaItem?.image = img! as UIImage
                        //self.collectionView!.reloadData()
                    }
                    
                    let message = JSQMessage(senderId: id, displayName: senderName as! String, media: mediaItem)
                    self.messages.append(message!)
                        
                    self.finishReceivingMessage()
                }
            }
        })
    }
    
    func reloadMessagesView() {
        self.collectionView?.reloadData()
    }
    
}


