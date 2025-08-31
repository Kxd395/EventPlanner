"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.validatePlacement = validatePlacement;
const shared_types_1 = require("@cathedral/shared-types");
const pieces_1 = require("./pieces");
const territory_1 = require("./territory");
const catalog = (0, pieces_1.buildCatalog)(true);
function validatePlacement(state, intent) {
    const piece = state.pieces[intent.pieceId];
    if (!piece)
        return { legal: false, reason: 'UNKNOWN_PIECE' };
    if (piece.placed)
        return { legal: false, reason: 'ALREADY_PLACED' };
    if (intent.anchor < 0 || intent.anchor >= state.board.length)
        return { legal: false, reason: 'OUT_OF_BOUNDS' };
    const shapeEntry = catalog[piece.pieceId];
    if (!shapeEntry)
        return { legal: false, reason: 'SHAPE_NOT_FOUND' };
    const variant = (0, pieces_1.findVariant)(shapeEntry, intent.rotation, intent.reflected) || shapeEntry.variants[0];
    const [ax, ay] = (0, shared_types_1.cellXY)(intent.anchor);
    for (const [dx, dy] of variant.cells) {
        const x = ax + dx;
        const y = ay + dy;
        if (x < 0 || x >= 10 || y < 0 || y >= 10)
            return { legal: false, reason: 'OUT_OF_BOUNDS' };
        const idx = (0, shared_types_1.xyToIndex)(x, y);
        if (state.board[idx])
            return { legal: false, reason: 'CELL_OCCUPIED' };
    }
    // Basic territory detection (captures still not implemented)
    const newT = (0, territory_1.detectNewTerritories)(state);
    const captures = (0, territory_1.detectCaptures)(state, piece.owner);
    return { legal: true, captures, newTerritories: newT };
}
