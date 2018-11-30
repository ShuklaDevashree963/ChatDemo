//
//  ViewController.swift
//  Chat
//
//  Created by SruthiPattuvakkari on 26/11/18.
//  Copyright © 2018 SruthiPattuvakkari. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    @IBOutlet weak var chatBtn: UIButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }

    @IBAction func chatBtnAtn(_ sender: UIButton) {
        
        let storyboard = UIStoryboard(name: "Main", bundle: nil)
        let viewController = storyboard.instantiateViewController(withIdentifier: "main") as! ChatViewController
        let navController = UINavigationController(rootViewController: viewController)

        navController.view.backgroundColor = UIColor.white
        //navController.navigationController?.isNavigationBarHidden = false
        navController.modalPresentationStyle = UIModalPresentationStyle.popover
        navController.popoverPresentationController?.permittedArrowDirections =  UIPopoverArrowDirection.up
        
        navController.preferredContentSize = CGSize(width: 455, height: 700)
        
        let popPresentCnt = navController.popoverPresentationController
        popPresentCnt?.sourceView = sender
        popPresentCnt?.sourceRect = sender.bounds
        popPresentCnt?.backgroundColor = UIColor.white
        present(navController, animated: true,completion: nil)

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
      
    }
    

}
