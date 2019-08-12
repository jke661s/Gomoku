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

    this.socket.on("replayApproved", function() {
        self.game.replayApproved()
    })
}

Player.prototype.joinGame = function(game) {
    this.game = game
}

function Game() {
    this.io = require('socket.io')(app)
    this.board = [
        ["", "", ""],
        ["", "", ""],
        ["", "", ""]
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
            console.log("room is full")
            socket.emit("roomFull")
        } else {
            console.log("Can be added")
            game.addPlayer(new Player(socket))
        }
    })
}

Game.prototype.addPlayer = function(player) {
    console.log("adding player")
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

Game.prototype.replayApproved = function() {
    this.player1.socket.emit("replayApproved")
    this.player2.socket.emit("replayApproved")
}

Game.prototype.startGame = function() {
    this.player1.socket.emit("currentTurn", "X")
    this.player2.socket.emit("currentTurn", "X")
    this.player1.socket.emit("startGame")
    this.player2.socket.emit("startGame")
}

// Start the game server
var game = new Game()
