//
//  GomokuViewController.swift
//  Gomoku
//
//  Created by iOS dev on 8/8/19.
//  Copyright © 2019 iOS dev. All rights reserved.
//

import UIKit
import SnapKit

class GomokuViewController: UIViewController {

    private var buttons: [UIButton] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }

    private func setUpUI() {
        
        self.view.backgroundColor = .white

        for i in 0...14 {
            
            print(i)
            
            
            let button = UIButton(type: .custom)
            button.backgroundColor = .red
            self.view.addSubview(button)
            button.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 15, height: 15))
            }
            
            if i == 0 {
                button.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview().offset(10)
                    make.top.equalToSuperview().offset(100)
                }
            } else {
                button.snp.makeConstraints { (make) in
                    make.top.equalTo(buttons[0])
                    make.leading.equalTo(buttons[i - 1].snp.trailing).offset(2)
                }
            }
            buttons.append(button)
        }
 
    }

}
