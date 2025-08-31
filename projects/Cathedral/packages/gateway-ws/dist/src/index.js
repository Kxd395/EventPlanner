"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const ws_1 = require("ws");
const game_engine_1 = require("@cathedral/game-engine");
const wss = new ws_1.WebSocketServer({ port: 8080 });
wss.on('connection', (ws) => {
    const game = (0, game_engine_1.newGame)();
    ws.send(JSON.stringify({ type: 'hello', gameId: game.id }));
});
console.log('Gateway WS listening on :8080');
