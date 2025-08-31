"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.baseShapes = void 0;
exports.baseShapes = [
    { id: 'CATHEDRAL', cells: [[0, 0], [1, 0], [0, 1], [1, 1], [2, 1]], area: 5 },
    { id: 'BISHOP', cells: [[0, 0], [1, 0], [0, 1], [0, 2]], area: 4 },
    { id: 'TOWER', cells: [[0, 0], [1, 0], [2, 0], [1, 1]], area: 4 },
    { id: 'WALL4', cells: [[0, 0], [1, 0], [2, 0], [3, 0]], area: 4 },
    { id: 'WALL3', cells: [[0, 0], [1, 0], [2, 0]], area: 3 },
    { id: 'COURTYARD', cells: [[0, 0], [1, 0], [0, 1], [1, 1]], area: 4 },
    { id: 'L_SHAPE', cells: [[0, 0], [0, 1], [0, 2], [1, 2]], area: 4 },
    { id: 'S_BEND', cells: [[0, 0], [1, 0], [1, 1], [2, 1]], area: 4 },
    { id: 'Z_BEND', cells: [[1, 0], [2, 0], [0, 1], [1, 1]], area: 4 },
    { id: 'SPIRE', cells: [[0, 0], [0, 1], [1, 1]], area: 3 },
    { id: 'WING', cells: [[0, 0], [1, 0], [2, 0], [2, 1]], area: 4 },
    { id: 'CROSS5', cells: [[1, 0], [0, 1], [1, 1], [2, 1], [1, 2]], area: 5 },
    { id: 'HOOK5', cells: [[0, 0], [0, 1], [0, 2], [1, 2], [2, 2]], area: 5 }
];
exports.default = exports.baseShapes;
