//
//  SystemAlert.swift
//  Gomoku
//
//  Created by iOS dev on 9/8/19.
//  Copyright © 2019 iOS dev. All rights reserved.
//

import Foundation
import UIKit

class SystemAlert {
    
    func getAlert(title: String, message: String, actions: [UIAlertAction]) -> UIAlertController {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        for action in actions {
            alert.addAction(action)
        }
        return alert
    }
    
}
