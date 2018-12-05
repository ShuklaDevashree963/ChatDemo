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
    var receiverUser : DataSnapshot? {
        didSet {
            inputToolbar.isHidden = false
            downloadMessages()
        }
    }
    
    lazy var outgoingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.outgoingMessagesBubbleImage(with: UIColor.jsq_messageBubbleBlue())
    }()
    
    lazy var incomingBubble: JSQMessagesBubbleImage = {
        return JSQMessagesBubbleImageFactory()!.incomingMessagesBubbleImage(with: UIColor.jsq_messageBubbleLightGray())
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if  let user = Auth.auth().currentUser {
            senderId = user.uid
            senderDisplayName = user.displayName ?? ""
        } else {
            senderId = String(arc4random_uniform(999999))
            senderDisplayName = ""
        }
        
        title = "\(senderDisplayName!)"
        
        let smilyButton = UIButton()
        smilyButton.setImage(#imageLiteral(resourceName: "Smiley"), for: UIControlState.normal)
        let attachmentButton = UIButton()
        attachmentButton.setImage(#imageLiteral(resourceName: "Attachment"), for: UIControlState.normal)
        
        inputToolbar.contentView.leftBarButtonItem = smilyButton
        inputToolbar.contentView.attachmentButtonItem = attachmentButton
        collectionView.collectionViewLayout.incomingAvatarViewSize = CGSize(width: 40, height: 40)
        collectionView.collectionViewLayout.outgoingAvatarViewSize = CGSize(width: 40, height: 40)
    
    }
    
    //--------------------------------------------------------------------------------
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if  FirebaseManager.shared.isLoggedIn {
            downloadMessages()
        } else {
            inputToolbar.isHidden = true
        }
    }
    
    //--------------------------------------------------------------------------------
    
    //Mark : Factory methods
    
    //--------------------------------------------------------------------------------
    
    func viewcontroller() -> ChatViewController {
        return StoryboardConstants.chatVC as! ChatViewController
    }

    override func collectionView(_ collectionView: JSQMessagesCollectionView!, messageDataForItemAt indexPath: IndexPath!) -> JSQMessageData! {
        return messages[indexPath.item]
    }
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
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
        let message = self.messages[indexPath.item]
        if indexPath?.item == 0 {
            return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
        }
        
        if (indexPath?.item ?? 0) - 1 > 0 {
            let previousMessage = messages[(indexPath?.item ?? 0) - 1] as? JSQMessage
            
            if let aDate = previousMessage?.date {
                if Int((message.date.timeIntervalSince(aDate) ?? 0.0) / 60) > 1 {
                    return JSQMessagesTimestampFormatter.shared().attributedTimestamp(for: message.date)
                }
            }
        }
        
        return nil
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
        let ref = Constants.FirebaseReferances.databaseChats.childByAutoId()
        
        let message = ["sender_id": senderId, "name": senderDisplayName, "text": text, "timestamp": [".sv":"timestamp"], "receiverUId" : receiverUser?.key as Any] as [String : Any]
        
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
                    print("failed to upload image",error as Any)
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
        let ref = Constants.FirebaseReferances.databaseChats.childByAutoId()
        let messageObject = [
            "text":" ",
            "sender_id":senderId,
            "name": senderDisplayName,
            "imageUrl":imageUrl,
            "timestamp": [".sv":"timestamp"], "receiverId" : receiverUser?.key as Any
            ] as [String:Any]
        ref.setValue(messageObject)
        finishSendingMessage()
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func downloadMessages() {
        
        messages.removeAll()
        
        let query = Constants.FirebaseReferances.databaseChats.queryLimited(toLast: 100)
        
        _ = query.observe(.childAdded, with: { [weak self] snapshot in
            
            if let data = snapshot.value as? [String:AnyObject], let id  = data["sender_id"] as? String, let senderName = data["name"] as? String, let timestamp = data["timestamp"] as? Double{
                
                let date = Date(timeIntervalSince1970: timestamp/1000)
                let receiverId = data["receiverId"] as? String
                
                if (![id, receiverId].contains(Auth.auth().currentUser?.uid)) {
                    return
                }
                
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
                    
                    self?.messages.append(JSQMessage(senderId: id, senderDisplayName: senderName, date: date, media: mediaItem))
                    self?.finishReceivingMessage()
                   
                    
                } else if let text = data["text"] as? String {
                   
                    self?.messages.append(JSQMessage(senderId: id, senderDisplayName: senderName, date: date, text: text))

                }
                
                self?.finishReceivingMessage()
            }
        })
    }
    
    func reloadMessagesView() {
        self.collectionView?.reloadData()
    }
}
