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

//    private var firstLineButtons: [MyButton] = []
//    private var Column0Buttons: [MyButton] = []
//    private var Column1Buttons: [MyButton] = []
//    private var Column2Buttons: [MyButton] = []
//    private var Column3Buttons: [MyButton] = []
//    private var Column4Buttons: [MyButton] = []
//    private var Column5Buttons: [MyButton] = []
//    private var Column6Buttons: [MyButton] = []
//    private var Column7Buttons: [MyButton] = []
//    private var Column8Buttons: [MyButton] = []
//    private var Column9Buttons: [MyButton] = []
//    private var Column10Buttons: [MyButton] = []
//    private var Column11Buttons: [MyButton] = []
//    private var Column12Buttons: [MyButton] = []
//    private var Column13Buttons: [MyButton] = []
//    private var Column14Buttons: [MyButton] = []
    struct Coord: Hashable {
        var x: Int
        var y: Int
    }
    
    private var buttonList: [Coord : MyButton] = [:]
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }

//    private func setUpUI() {
//
//        self.view.backgroundColor = .white
//
//        for i in 0...14 {
//            let button = MyButton(type: .custom)
//            button.backgroundColor = .red
//            button.setPressAnimation()
//            self.view.addSubview(button)
//            button.snp.makeConstraints { (make) in
//                make.size.equalTo(CGSize(width: 20, height: 20))
//            }
//
//            if i == 0 {
//                button.snp.makeConstraints { (make) in
//                    make.leading.equalToSuperview().offset(10)
//                    make.top.equalToSuperview().offset(100)
//                }
//            } else {
//                button.snp.makeConstraints { (make) in
//                    make.top.equalTo(self.firstLineButtons[0])
//                    make.leading.equalTo(self.firstLineButtons[i - 1].snp.trailing).offset(5)
//                }
//            }
//            firstLineButtons.append(button)
//            for j in 1...14 {
//                let button = MyButton(type: .custom)
//                button.backgroundColor = .blue
//                button.setPressAnimation()
//                self.view.addSubview(button)
//
//                if j == 1 {
//                    button.snp.makeConstraints { (make) in
//                        make.size.equalTo(CGSize(width: 20, height: 20))
//                        make.top.equalTo(self.firstLineButtons[i].snp.bottom).offset(5)
//                        make.leading.equalTo(self.firstLineButtons[i])
//                    }
//                } else {
//                    button.snp.makeConstraints { (make) in
//                        make.size.equalTo(CGSize(width: 20, height: 20))
//                        make.top.equalTo(self.Column0Buttons[j - 2].snp.bottom).offset(5)
//                        make.leading.equalTo(self.firstLineButtons[i])
//                    }
//                }
//                Column0Buttons.append(button)
//            }
//
//        }
//
//
//
//    }

    private func setUpUI() {
        self.view.backgroundColor = .white
        for x in 1...15 {
            let btn = MyButton(type: .custom)
            btn.backgroundColor = .gray
            btn.coord.0 = x
            btn.coord.1 = 1
            btn.addTarget(self, action: #selector(onTap), for: .touchUpInside)
            self.view.addSubview(btn)
                btn.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 15, height: 15))
            }
            if x == 1 {
                btn.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview().offset(10)
                    make.top.equalToSuperview().offset(100)
                }
            } else {
                let coord = Coord(x: (x - 1), y: 1)
                guard let leftBtn = buttonList[coord] else { continue }
                btn.snp.makeConstraints { (make) in
                    make.leading.equalTo(leftBtn.snp.trailing).offset(10)
                    make.top.equalToSuperview().offset(100)
                }
            }
            let coord = Coord(x: x, y: 1)
            buttonList[coord] = btn
            for y in 2...15 {
                let btny = MyButton(type: .custom)
                btny.backgroundColor = .gray
                btny.coord.0 = x
                btny.coord.1 = y
                btny.addTarget(self, action: #selector(onTap), for: .touchUpInside)
                self.view.addSubview(btny)
                btny.snp.makeConstraints { (make) in
                    make.size.equalTo(CGSize(width: 15, height: 15))
                }
                let coord = Coord(x:x , y: (y - 1))
                guard let topBtn = buttonList[coord] else { continue }
                btny.snp.makeConstraints { (make) in
                    make.leading.equalTo(btn)
                    make.top.equalTo(topBtn.snp.bottom).offset(10)
                }
                let coord1 = Coord(x: x, y: y)
                buttonList[coord1] = btny
            }
        }
    }
    
    @objc private func onTap(btn: MyButton) {
        btn.backgroundColor = .red
        btn.isUserInteractionEnabled = false
        print(btn.coord)
    }
    
    
}
