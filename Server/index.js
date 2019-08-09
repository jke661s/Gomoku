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
        if (game.player2 === null) {
            console.log("Can be added")
            game.addPlayer(new Player(socket))
        } else {
            console.log("room is full")
            socket.emit("roomFull")
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
        this.startGame()
    }
}

Game.prototype.playerMove = function(player, x, y) {
    this.player1.socket.emit("playerMove", player["name"], x, y)
    this.player2.socket.emit("playerMove", player["name"], x, y)
    if (player["name"] === "X") {
        this.player1.socket.emit("currentTurn","0")
        this.player2.socket.emit("currentTurn","0")
    } else {
        this.player1.socket.emit("currentTurn","X")
        this.player2.socket.emit("currentTurn","X")
    }
}

Game.prototype.startGame = function() {
    this.player1.socket.emit("startGame")
    this.player2.socket.emit("startGame")
}

// Start the game server
var game = new Game()
