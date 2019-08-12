var app = require('http').createServer()

app.listen(8900)

function Player(socket) {
    var self = this
    this.socket = socket
    this.name = ""
    this.game = {}

    this.socket.on("playerMove", function(x, y) {
        self.game.playerMove(self, x, y)
    })

    this.socket.on("quit", function(name) {
        if (name === "X") {
            self.game.player1 = null
        } else if (name === "O") {
            self.game.player2 = null
        }
    })

    this.socket.on("replayRequest", function(name) {
        self.game.replayRequest(name)
    })

    this.socket.on("replayRejected", function(name) {
        self.game.replayRejected(name)
    })

    this.socket.on("restart", function() {
        self.game.restart()
    })
}

Player.prototype.joinGame = function(game) {
    this.game = game
}

function Game() {
    this.io = require('socket.io')(app)
    this.board = [
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""]
    ]
    this.player1 = null
    this.player2 = null
    this.currentTurn = "X"
    this.moveCount = 0
    this.started = false
    this.addHandlers()
}

Game.prototype.addHandlers = function() {
    var game = this

    this.io.sockets.on("connection", function(socket) {
        if (game.player2 !== null && game.player1 !== null) {
            socket.emit("roomFull")
        } else {
            game.addPlayer(new Player(socket))
        }
    })
}

Game.prototype.addPlayer = function(player) {
    if (this.player1 === null) {
        this.player1 = player
        this.player1["game"] = this
        this.player1["name"] = "X"
        this.player1.socket.emit("name", "X")
    } else if (this.player2 === null) {
        this.player2 = player
        this.player2["game"] = this
        this.player2["name"] = "O"
        this.player2.socket.emit("name", "O")
    }
    if (this.player1 !== null && this.player2 !== null) {
        this.startGame()
    }
}

Game.prototype.playerMove = function(player, x, y) {
    this.player1.socket.emit("playerMove", player["name"], x, y)
    this.player2.socket.emit("playerMove", player["name"], x, y)
    this.board[x][y] = player["name"]

    // Check cul
    var c = 1
    for (var i = 0; i < 14; i++) {
        if (this.board[x][i] === player["name"] && this.board[x][i] == this.board[x][i+1]) {
            c++
            if (c === 5) {
                this.announceWin(player)
                return
            }
        } else {
            c = 1
        }
    }
    // Check row
    var r = 1
    for (var i = 0; i < 14; i++) {
        if (this.board[i][y] === player["name"] && this.board[i][y] == this.board[i+1][y]) {
            r++
            if (r === 5) {
                this.announceWin(player)
                return
            }
        } else {
            r = 1
        }
    }
    // Check diags
    for (var i = 0; i < 11; i++) {
        for (var j = 0; j < 11; j++) {
            if (this.board[i][j] === player["name"] && this.board[i+1][j+1] === player["name"] 
            && this.board[i+2][j+2] === player["name"] && this.board[i+3][j+3] === player["name"] 
            && this.board[i+4][j+4] === player["name"]) {
                this.announceWin(player)
                return
            }
        }
    }
    for (var i = 4; i < 15; i++) {
        for (var j = 0; j < 11; j++) {
            if (this.board[i][j] === player["name"] && this.board[i-1][j+1] === player["name"] 
            && this.board[i-2][j+2] === player["name"] && this.board[i-3][j+3] === player["name"] 
            && this.board[i-4][j+4] === player["name"]) {
                this.announceWin(player)
                return
            }
        }
    }

    if (player["name"] === "X") {
        this.player1.socket.emit("currentTurn", "O")
        this.player2.socket.emit("currentTurn", "O")
    } else {
        this.player1.socket.emit("currentTurn", "X")
        this.player2.socket.emit("currentTurn", "X")
    }
}

Game.prototype.replayRequest = function(name) {
    this.player1.socket.emit("replayRequest", name)
    this.player2.socket.emit("replayRequest", name)
}

Game.prototype.replayRejected = function(name) {
    this.player1.socket.emit("replayRejected", name)
    this.player2.socket.emit("replayRejected", name)
}

Game.prototype.restart = function() {
    var self = this
    this.board = [
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""],
        ["", "", "", "", "", "", "", "", "", "", "", "", "", "", ""]
    ]
    if (self.player1["name"] === "X") {
        self.player1["name"] = "O"
        self.player1.socket.emit("name", "O")
        self.player2["name"] = "X"
        self.player2.socket.emit("name", "X")
    } else {
        self.player1["name"] = "X"
        self.player1.socket.emit("name", "X")
        self.player2["name"] = "O"
        self.player2.socket.emit("name", "O")
    }
    this.player1.socket.emit("restart")
    this.player2.socket.emit("restart")
    this.player1.socket.emit("currentTurn", "X")
    this.player2.socket.emit("currentTurn", "X")
}

Game.prototype.startGame = function() {
    this.player1.socket.emit("currentTurn", "X")
    this.player2.socket.emit("currentTurn", "X")
    this.player1.socket.emit("startGame")
    this.player2.socket.emit("startGame")
}

Game.prototype.announceWin = function(player) {
    this.player1.socket.emit("win", player["name"])
    this.player2.socket.emit("win", player["name"])
}

// Start the game server
var game = new Game()
