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
    private let userInfoLabel = UILabel()
    private var myColor = UIColor() 
    private var otherPartyColor = UIColor()
    private let statusLabel = UILabel()
    
    private struct Coord: Hashable {
        var x: Int
        var y: Int
    }
    
    private let manager = SocketManager(socketURL: URL(string: "http://192.168.0.104:8900")!, config: [.log(false), .compress])
    private var socket: SocketIOClient!
    private var resetAck: SocketAckEmitter?
    private var name = "" {
        didSet {
            switch self.name {
            case "X":
                myColor = .black
                self.userInfoLabel.text = "You are playing black"
                otherPartyColor = .white
            case "O":
                myColor = .white
                self.userInfoLabel.text = "You are playing white"
                otherPartyColor = .black
            default:
                return
            }
        }
    }
    

    override func viewDidLoad() {
        super.viewDidLoad()
        socket = manager.defaultSocket
        addSocketHandlers()
        setUpUI()
        setListener()
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
            self.statusLabel.text = "Waiting for another player coming..."
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
            self.userInfoLabel.isHidden = false
            self.playButton.setTitle("Replay", for: .normal)
            self.playButton.removeTarget(nil, action: nil, for: .touchUpInside)
            self.playButton.addTarget(self, action: #selector(self.onReplay), for: .touchUpInside)
        }
        
        socket.on("currentTurn") { [weak self] data, ack in
            guard let self = self, let turn = data[0] as? String else {return}
            if turn == self.name {
                self.yourTurn()
                self.statusLabel.text = "It's your turn now."
            } else {
                self.statusLabel.text = "It's NOT your turn!"
            }
        }
        
        socket.on("replayRequest") { [weak self] data, ack in
            guard let self = self, let name = data[0] as? String, name != self.name else {return}
            let alert = SystemAlert().getAlert(title: "Agree to replay?", message: "Your competitor has applied for replaying the game. Do you agree to replay?", actions: [UIAlertAction(title: "No", style: .default, handler: { [weak self] action in
                guard let self = self else {return}
                self.socket.emit("replayRejected", self.name)
            }),UIAlertAction(title: "Yes", style: .default, handler: { [weak self] (action) in
                guard let self = self else {return}
                self.socket.emit("restart")
            })])
            self.present(alert, animated: true)
        }
        
        socket.on("replayRejected") { [weak self] data, ack in
            guard let self = self, let name = data[0] as? String, name != self.name else {return}
            let alert = SystemAlert().getAlert(title: "Bad luck", message: "Your replay request has been rejected", actions: [UIAlertAction(title: "OK", style: .default, handler: nil)])
            self.present(alert, animated: true)
        }
        
        socket.on("restart") { [weak self] data, ack in
            guard let self = self else {return}
            self.gameReset()
        }
        
        socket.on("win") { [weak self] data, ack in
            guard let self = self, let winner = data[0] as? String else {return}
            if winner == self.name {
                let alert = SystemAlert().getAlert(title: "Congratulations!", message: "You won the game! Try again :)", actions: [UIAlertAction(title: "OK", style: .default, handler: nil)])
                self.present(alert, animated: true)
            } else {
                let alert = SystemAlert().getAlert(title: "Bad luck :(", message: "You lost the game. Try again!", actions: [UIAlertAction(title: "OK", style: .default, handler: nil)])
                self.present(alert, animated: true)
            }
        }
    }
    
    private func gameReset() {
        disableAllButtons()
        for btn in buttonList {
            btn.1.backgroundColor = nil
        }
    }
    
    private func holdPlayerMove(coord: Coord) {
        guard let button = buttonList[coord] else {return}
        gameView.bringSubviewToFront(button)
        button.backgroundColor = otherPartyColor
        button.isUserInteractionEnabled = false
    }
    
    private func setListener() {
        NotificationCenter.default.addObserver(self, selector: #selector(applicationWillTerminate(notification:)), name: UIApplication.willTerminateNotification, object: nil)
    }
    
    @objc func applicationWillTerminate(notification: Notification) {
        socket.emit("quit", self.name)
        socket.disconnect()
    }
    
    private func setUpUI() {
        self.view.backgroundColor = .white
        self.gameView.backgroundColor = goBoardColor
        setUpButtons()
        disableAllButtons()
        setUpLines()
        
        self.view.addSubview(statusLabel)
        statusLabel.snp.makeConstraints { (make) in
            make.height.equalTo(100)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(25)
        }
        statusLabel.text = ""
        statusLabel.textColor = .black
        
        
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
        
        self.view.addSubview(userInfoLabel)
        userInfoLabel.snp.makeConstraints { (make) in
            make.height.equalTo(50)
            make.centerX.equalToSuperview()
            make.top.equalTo(playButton.snp.bottom).offset(10)
        }
        userInfoLabel.isHidden = true
        userInfoLabel.textColor = .gray
    }
    
    @objc private func onPlayButton() {
        socket.connect()
    }
    
    @objc private func onReplay() {
        socket.emit("replayRequest", self.name)
    }
    
    private func disableAllButtons() {
        for btn in buttonList {
            btn.value.isUserInteractionEnabled = false
        }
    }
    
    private func yourTurn() {
        for btn in buttonList {
            guard btn.1.backgroundColor == nil else {continue}
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
        for x in 0...14 {
            let btn = MyButton(type: .custom)
//            btn.backgroundColor = .gray
            btn.coord.0 = x
            btn.coord.1 = 0
            btn.addTarget(self, action: #selector(onTap), for: .touchUpInside)
            self.gameView.addSubview(btn)
            btn.snp.makeConstraints { (make) in
                make.size.equalTo(CGSize(width: 15, height: 15))
            }
            if x == 0 {
                btn.snp.makeConstraints { (make) in
                    make.leading.equalToSuperview()
                    make.top.equalToSuperview()
                }
            } else if x == 14 {
                let coord = Coord(x: (x - 1), y: 0)
                guard let leftBtn = buttonList[coord] else { continue }
                btn.snp.makeConstraints { (make) in
                    make.leading.equalTo(leftBtn.snp.trailing).offset(10)
                    make.top.equalToSuperview()
                    make.trailing.equalToSuperview()
                }
            } else {
                let coord = Coord(x: (x - 1), y: 0)
                guard let leftBtn = buttonList[coord] else { continue }
                btn.snp.makeConstraints { (make) in
                    make.leading.equalTo(leftBtn.snp.trailing).offset(10)
                    make.top.equalToSuperview()
                }
            }
            gameView.layoutIfNeeded()
            btn.layer.cornerRadius = btn.frame.size.height/2
            btn.layer.masksToBounds = true
            let coord = Coord(x: x, y: 0)
            buttonList[coord] = btn
            for y in 1...14 {
                let btny = MyButton(type: .custom)
//                btny.backgroundColor = .gray
                btny.coord.0 = x
                btny.coord.1 = y
                btny.addTarget(self, action: #selector(onTap), for: .touchUpInside)
                self.gameView.addSubview(btny)
                btny.snp.makeConstraints { (make) in
                    make.size.equalTo(CGSize(width: 15, height: 15))
                }
                if y == 14 {
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
        for j in 0...14 {
            let line = UIView()
            line.isUserInteractionEnabled = false
            line.backgroundColor = .black
            self.gameView.addSubview(line)
            line.snp.makeConstraints { (make) in
                make.height.equalTo(1)
                guard let button1 = buttonList[Coord(x:0,y:j)], let button2 = buttonList[Coord(x:14,y:j)] else {
                    print("There are no buttons")
                    return}
                make.leading.equalTo(button1.snp.centerX)
                make.trailing.equalTo(button2.snp.centerX)
                make.centerY.equalTo(button1)
            }
        }
        for i in 0...14 {
            let line = UIView()
            line.isUserInteractionEnabled = false
            line.backgroundColor = .black
            self.gameView.addSubview(line)
            line.snp.makeConstraints { (make) in
                make.width.equalTo(1)
                guard let button1 = buttonList[Coord(x:i,y:0)], let button2 = buttonList[Coord(x:i,y:14)] else {
                    print("There are no buttons")
                    return}
                make.top.equalTo(button1.snp.centerY)
                make.bottom.equalTo(button2.snp.centerY)
                make.centerX.equalTo(button1)
            }
        }
    }
    
    @objc private func onTap(btn: MyButton) {
        gameView.bringSubviewToFront(btn)
        btn.backgroundColor = myColor
        disableAllButtons()
        socket.emit("playerMove", btn.coord.0, btn.coord.1)
    }
    
    
}
