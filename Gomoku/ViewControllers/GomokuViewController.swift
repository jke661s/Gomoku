//
//  GomokuViewController.swift
//  Gomoku
//
//  Created by iOS dev on 8/8/19.
//  Copyright © 2019 iOS dev. All rights reserved.
//

import UIKit
import SnapKit
import SocketIO

class GomokuViewController: UIViewController {

    private let gameView = UIView()
    private let playButton = MyButton(type: .custom)
    private var buttonList: [Coord : MyButton] = [:]
    private var currentTurn = ""
    
    private struct Coord: Hashable {
        var x: Int
        var y: Int
    }
    
    private let manager = SocketManager(socketURL: URL(string: "http://192.168.0.104:8900")!, config: [.log(false), .compress])
    private var socket: SocketIOClient!
    private var resetAck: SocketAckEmitter?
    private var name = ""
    

    override func viewDidLoad() {
        super.viewDidLoad()
        socket = manager.defaultSocket
        addSocketHandlers()
        setUpUI()
    }
    
    private func addSocketHandlers() {
        socket.on("playerMove") { [weak self] data, ack in
            guard let self = self, let name = data[0] as? String, let x = data[1] as? Int, let y = data[2] as? Int else {return}
            guard name != self.name else {return}
            self.holdPlayerMove(coord: Coord(x: x, y: y))
        }
        
        socket.on("name") { [weak self] data, ack in
            guard let self = self,let name = data[0] as? String else {return}
            self.name = name
            print("My name is: ", name)
        }
        
        socket.on("roomFull") { [weak self] data, ack in
            guard let self = self else {return}
            let alert = SystemAlert().getAlert(title: "Hey, you are too late!", message: "The room is full now. Please try again later.", actions: [UIAlertAction(title: "OK", style: .default, handler: { [weak self] _ in
                guard let self = self else {return}
                self.socket.disconnect()
            })])
            self.present(alert, animated: true)
        }
        
        socket.on("startGame") { [weak self] data, ack in
            guard let self = self else {return}
            self.enableAllButtons()
        }
        
        socket.on("currentTurn"){ [weak self] data, ack in
            guard let self = self, let turn = data[0] as? String else {return}
            if turn == self.name {
                self.yourTurn()
            }
            
        }
    }
    
    private func holdPlayerMove(coord: Coord) {
        guard let button = buttonList[coord] else {return}
        gameView.bringSubviewToFront(button)
        button.backgroundColor = .blue
        button.isUserInteractionEnabled = false
    }
    
    private func setUpUI() {
        self.view.backgroundColor = .white
        self.gameView.backgroundColor = .gray
        setUpButtons()
        disableAllButtons()
        setUpLines()
        
        playButton.setTitle("Play", for: .normal)
        playButton.setTitleColor(.gray, for: .normal)
        playButton.layer.borderWidth = 1
        playButton.layer.borderColor = UIColor.gray.cgColor
        playButton.setPressAnimation()
        playButton.addTarget(self, action: #selector(onPlayButton), for: .touchUpInside)
        self.view.addSubview(playButton)
        playButton.snp.makeConstraints { (make) in
            make.top.equalTo(gameView.snp.bottom).offset(20)
            make.centerX.equalToSuperview()
            make.size.equalTo(CGSize(width: 100, height: 40))
        }
    }
    
    @objc private func onPlayButton() {
        socket.connect()
    }
    
    private func disableAllButtons() {
        for btn in buttonList {
            btn.value.isUserInteractionEnabled = false
        }
    }
    
    private func yourTurn() {
        for btn in buttonList {
            guard btn.1.backgroundColor == .red else {return}
            btn.1.isUserInteractionEnabled = true
        }
    }
    
    private func enableAllButtons() {
        for btn in buttonList {
            btn.value.isUserInteractionEnabled = true
        }
    }
    
    private func setUpButtons() {
        self.view.addSubview(gameView)
        gameView.snp.makeConstraints { (make) in
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(100)
        }
        for x in 1...15 {
            let btn = MyButton(type: .custom)
//            btn.backgroundColor = .gray
            btn.coord.0 = x
            btn.coord.1 = 1
            btn.addTarget(self, action: #selector(onTap), for: .touchUpInside)
            self.gameView.addSubview(btn)
            btn.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 15, height: 15))
            }
            if x == 1 {
                btn.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview()
                    make.top.equalToSuperview()
                }
            } else if x == 15 {
                let coord = Coord(x: (x - 1), y: 1)
                guard let leftBtn = buttonList[coord] else { continue }
                btn.snp.makeConstraints { (make) in
                    make.leading.equalTo(leftBtn.snp.trailing).offset(10)
                    make.top.equalToSuperview()
                    make.trailing.equalToSuperview()
                }
            } else {
                let coord = Coord(x: (x - 1), y: 1)
                guard let leftBtn = buttonList[coord] else { continue }
                btn.snp.makeConstraints { (make) in
                    make.leading.equalTo(leftBtn.snp.trailing).offset(10)
                    make.top.equalToSuperview()
                }
            }
            gameView.layoutIfNeeded()
            btn.layer.cornerRadius = btn.frame.size.height/2
            btn.layer.masksToBounds = true
            let coord = Coord(x: x, y: 1)
            buttonList[coord] = btn
            for y in 2...15 {
                let btny = MyButton(type: .custom)
//                btny.backgroundColor = .gray
                btny.coord.0 = x
                btny.coord.1 = y
                btny.addTarget(self, action: #selector(onTap), for: .touchUpInside)
                self.gameView.addSubview(btny)
                btny.snp.makeConstraints { (make) in
                    make.size.equalTo(CGSize(width: 15, height: 15))
                }
                if y == 15 {
                    let coord = Coord(x:x , y: (y - 1))
                    guard let topBtn = buttonList[coord] else { continue }
                    btny.snp.makeConstraints { (make) in
                        make.leading.equalTo(btn)
                        make.top.equalTo(topBtn.snp.bottom).offset(10)
                        make.bottom.equalToSuperview()
                    }
                } else {
                    let coord = Coord(x:x , y: (y - 1))
                    guard let topBtn = buttonList[coord] else { continue }
                    btny.snp.makeConstraints { (make) in
                        make.leading.equalTo(btn)
                        make.top.equalTo(topBtn.snp.bottom).offset(10)
                    }
                }
                gameView.layoutIfNeeded()
                btny.layer.cornerRadius = btn.frame.size.height/2
                btny.layer.masksToBounds = true
                let coord1 = Coord(x: x, y: y)
                buttonList[coord1] = btny
            }
        }

    }
    
    private func setUpLines() {
        for j in 1...15 {
            let line = UIView()
            line.isUserInteractionEnabled = false
            line.backgroundColor = .black
            self.gameView.addSubview(line)
            line.snp.makeConstraints { (make) in
                make.height.equalTo(2)
                guard let button1 = buttonList[Coord(x:1,y:j)], let button2 = buttonList[Coord(x:15,y:j)] else {
                    print("There is no buttons")
                    return}
                make.leading.equalTo(button1.snp.centerX)
                make.trailing.equalTo(button2.snp.centerX)
                make.centerY.equalTo(button1)
            }
        }
        for i in 1...15 {
            let line = UIView()
            line.isUserInteractionEnabled = false
            line.backgroundColor = .black
            self.gameView.addSubview(line)
            line.snp.makeConstraints { (make) in
                make.width.equalTo(2)
                guard let button1 = buttonList[Coord(x:i,y:1)], let button2 = buttonList[Coord(x:i,y:15)] else {
                    print("There is no buttons")
                    return}
                make.top.equalTo(button1.snp.centerY)
                make.bottom.equalTo(button2.snp.centerY)
                make.centerX.equalTo(button1)
            }
        }
    }
    
    @objc private func onTap(btn: MyButton) {
        gameView.bringSubviewToFront(btn)
        btn.backgroundColor = .red
        disableAllButtons()
        socket.emit("playerMove", btn.coord.0, btn.coord.1)
    }
    
    
}
