//
//  UIButtonExtension.swift
//  Gomoku
//
//  Created by iOS dev on 8/8/19.
//  Copyright © 2019 iOS dev. All rights reserved.
//

import Foundation
import UIKit

class MyButton: UIButton {
    
    var i: Int = -999
    var j: Int = -999
    var coord: (Int, Int) = (-999, -999)
    
    func setPressAnimation() {
        addTarget(self, action: #selector(pressed), for: .touchDown)
        addTarget(self, action: #selector(unpressed), for: .touchUpInside)
        addTarget(self, action: #selector(unpressed), for: .touchUpOutside)
    }
    
    @objc private func pressed() {
        UIButton.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .curveEaseIn], animations: {
            self.transform = CGAffineTransform(scaleX: 0.97, y: 0.97)
        }, completion: nil)
    }
    
    @objc private func unpressed() {
        UIButton.animate(withDuration: 0.1, delay: 0.0, options: [.allowUserInteraction, .curveEaseOut], animations: {
            self.transform = CGAffineTransform.identity
        }, completion: nil)
    }
}
