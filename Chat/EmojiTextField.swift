//
//  EmojiTextField.swift
//  Chat
//
//  Created by SruthiPattuvakkari on 22/11/18.
//  Copyright © 2018 SruthiPattuvakkari. All rights reserved.
//

import Foundation
import UIKit

class EmojiTextField: UITextView {
    
    override var textInputMode: UITextInputMode? {
        for mode in UITextInputMode.activeInputModes {
            if mode.primaryLanguage == "emoji" {
                return mode
            }
        }
        return nil
    }
}
