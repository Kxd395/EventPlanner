"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.applyPlacement = applyPlacement;
const shared_types_1 = require("@cathedral/shared-types");
const pieces_1 = require("./pieces");
const catalog = (0, pieces_1.buildCatalog)(true);
function applyPlacement(state, intent, validation) {
    const piece = state.pieces[intent.pieceId];
    piece.placed = true;
    piece.anchor = intent.anchor;
    piece.rotation = intent.rotation;
    piece.reflected = intent.reflected;
    // Fill board cells using orientation
    const entry = catalog[piece.pieceId];
    const variant = (0, pieces_1.findVariant)(entry, piece.rotation, piece.reflected) || entry.variants[0];
    const [ax, ay] = (0, shared_types_1.cellXY)(piece.anchor);
    for (const [dx, dy] of variant.cells) {
        const idx = (0, shared_types_1.xyToIndex)(ax + dx, ay + dy);
        state.board[idx] = piece;
    }
    // Apply captures: remove opponent pieces
    processCaptures(state, piece.owner, validation.captures);
    // Update scores (simple: territory cells + placed piece areas - captured pieces areas)
    state.scores = recomputeScores(state);
    // End-game detection: all pieces placed or no legal moves (simplified: all non-captured pieces placed)
    detectEndGame(state);
    // History append (simplified)
    // Persist new territories
    for (const t of validation.newTerritories || []) {
        state.territories[t.id] = t;
    }
    state.history.push({
        ply: state.history.length + 1,
        pieceId: intent.pieceId,
        applied: true,
        capturedPieceIds: validation.captures || [],
        newTerritories: (validation.newTerritories || []).map(t => t.id),
        scores: state.scores
    });
    state.turn = state.turn === 'LIGHT' ? 'DARK' : 'LIGHT';
}
function processCaptures(state, player, captures) {
    if (!captures?.length)
        return;
    for (const pid of captures) {
        for (let i = 0; i < state.board.length; i++) {
            const occ = state.board[i];
            if (occ && occ.pieceId === pid && occ.owner !== player) {
                occ.captured = true;
                state.board[i] = null;
            }
        }
    }
}
function recomputeScores(state) {
    return {
        LIGHT: computeScore(state, 'LIGHT'),
        DARK: computeScore(state, 'DARK')
    };
}
function detectEndGame(state) {
    if (state.finished)
        return;
    const remaining = Object.values(state.pieces).filter(p => p.owner !== 'NEUTRAL' && !p.captured && !p.placed);
    if (remaining.length)
        return;
    state.finished = true;
    const { LIGHT, DARK } = state.scores || { LIGHT: 0, DARK: 0 };
    if (LIGHT !== DARK)
        state.winner = LIGHT > DARK ? 'LIGHT' : 'DARK';
}
function computeScore(state, player) {
    // Sum areas of placed pieces not captured + territory cell count
    const territoryCells = Object.values(state.territories).filter(t => t.owner === player).reduce((a, t) => a + t.cells.length, 0);
    const pieceArea = Object.values(state.pieces).filter(p => p.owner === player && p.placed && !p.captured).reduce((a, p) => a + lookupArea(p.pieceId), 0);
    return territoryCells + pieceArea;
}
function lookupArea(pieceId) {
    // crude mapping fallback: infer from catalog if available
    const entry = catalog[pieceId];
    return entry ? entry.area : 0;
}
