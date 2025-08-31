"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.detectNewTerritories = detectNewTerritories;
exports.detectCaptures = detectCaptures;
const shared_types_1 = require("@cathedral/shared-types");
function exploreRegion(state, start, visited) {
    const regionCells = [];
    const stack = [start];
    visited[start] = true;
    let touchesEdge = false;
    const borderingOwners = new Set();
    while (stack.length) {
        const idx = stack.pop();
        regionCells.push(idx);
        const [x, y] = (0, shared_types_1.cellXY)(idx);
        if (x === 0 || x === 9 || y === 0 || y === 9)
            touchesEdge = true;
        addNeighbors(state, x, y, visited, stack, borderingOwners);
    }
    return { cells: regionCells, touchesEdge, borderingOwners };
}
function addNeighbors(state, x, y, visited, stack, borderingOwners) {
    const neighbors = [[x + 1, y], [x - 1, y], [x, y + 1], [x, y - 1]];
    for (const [nx, ny] of neighbors) {
        if (nx < 0 || nx > 9 || ny < 0 || ny > 9)
            continue;
        const nIdx = (0, shared_types_1.xyToIndex)(nx, ny);
        const occupant = state.board[nIdx];
        if (!occupant) {
            if (!visited[nIdx]) {
                visited[nIdx] = true;
                stack.push(nIdx);
            }
        }
        else if (occupant.owner !== 'NEUTRAL') {
            borderingOwners.add(occupant.owner);
        }
    }
}
function isNewRegion(state, cells) {
    return !cells.some(c => Object.values(state.territories).some(t => t.cells.includes(c)));
}
// Simple flood-fill to find enclosed empty regions fully surrounded by one player's pieces and not touching edge.
function detectNewTerritories(state) {
    const visited = new Array(100).fill(false);
    const regions = [];
    for (let i = 0; i < 100; i++) {
        if (visited[i] || state.board[i])
            continue;
        const { cells, touchesEdge, borderingOwners } = exploreRegion(state, i, visited);
        if (!touchesEdge && borderingOwners.size === 1 && isNewRegion(state, cells)) {
            const owner = borderingOwners.values().next().value;
            regions.push({ id: `T${Date.now()}_${state.history.length}_${regions.length}`, owner, cells });
        }
    }
    return regions;
}
// Capture detection: if opponent piece cells are fully enclosed inside a single player's territories after a move.
function detectCaptures(state, player) {
    const opponent = player === 'LIGHT' ? 'DARK' : 'LIGHT';
    const captured = [];
    // Build a set of all territory cells owned by player
    const ownedTerritoryCells = new Set();
    for (const t of Object.values(state.territories)) {
        if (t.owner === player)
            t.cells.forEach(c => ownedTerritoryCells.add(c));
    }
    // Opponent pieces that have all their occupied cells inside player territory become captured.
    const occupiedCellsByPiece = {};
    state.board.forEach((p, idx) => {
        if (p && p.owner === opponent && !p.captured) {
            if (!occupiedCellsByPiece[p.pieceId])
                occupiedCellsByPiece[p.pieceId] = [];
            occupiedCellsByPiece[p.pieceId].push(idx);
        }
    });
    for (const [pid, cells] of Object.entries(occupiedCellsByPiece)) {
        if (cells.every(c => ownedTerritoryCells.has(c)))
            captured.push(pid);
    }
    return captured;
}
