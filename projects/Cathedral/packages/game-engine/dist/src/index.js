"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.generateInitialPieces = void 0;
exports.newGame = newGame;
exports.attemptPlacement = attemptPlacement;
const shared_types_1 = require("@cathedral/shared-types");
const pieces_1 = require("./pieces");
Object.defineProperty(exports, "generateInitialPieces", { enumerable: true, get: function () { return pieces_1.generateInitialPieces; } });
const validate_1 = require("./validate");
const mutate_1 = require("./mutate");
let gameCounter = 0;
function newGame(id, _config = shared_types_1.DEFAULT_ENGINE_CONFIG) {
    const gameId = id ?? `game_${Date.now()}_${++gameCounter}`;
    const board = Array(100).fill(null);
    const pieces = (0, pieces_1.generateInitialPieces)();
    return {
        id: gameId,
        turn: 'LIGHT',
        board,
        pieces,
        territories: {},
        history: [],
        cathedralPlaced: false,
        scores: { LIGHT: 0, DARK: 0 },
        finished: false
    };
}
function attemptPlacement(state, intent) {
    const validation = (0, validate_1.validatePlacement)(state, intent);
    if (!validation.legal)
        return validation;
    (0, mutate_1.applyPlacement)(state, intent, validation);
    return validation;
}
