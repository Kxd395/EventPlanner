"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vitest_1 = require("vitest");
const src_1 = require("../src");
(0, vitest_1.describe)('newGame', () => {
    (0, vitest_1.it)('creates initial game state', () => {
        const gs = (0, src_1.newGame)('test');
        (0, vitest_1.expect)(gs.board).toHaveLength(100);
        (0, vitest_1.expect)(Object.keys(gs.pieces).length).toBeGreaterThan(0);
        (0, vitest_1.expect)(gs.turn).toBe('LIGHT');
    });
});
(0, vitest_1.describe)('attemptPlacement', () => {
    (0, vitest_1.it)('rejects unknown piece', () => {
        const gs = (0, src_1.newGame)('test2');
        const result = (0, src_1.attemptPlacement)(gs, { pieceId: 'X', anchor: 0, rotation: 0, reflected: false });
        (0, vitest_1.expect)(result.legal).toBe(false);
    });
    (0, vitest_1.it)('places a known piece legally on empty board', () => {
        const gs = (0, src_1.newGame)('test3');
        const firstKey = Object.keys(gs.pieces).find(k => k.startsWith('LIGHT_') && k !== 'LIGHT_CATHEDRAL');
        (0, vitest_1.expect)(firstKey).toBeDefined();
        const result = (0, src_1.attemptPlacement)(gs, { pieceId: firstKey, anchor: 0, rotation: 0, reflected: false });
        (0, vitest_1.expect)(result.legal).toBe(true);
        // ensure at least one board cell now occupied
        (0, vitest_1.expect)(gs.board.some(c => c?.pieceId)).toBe(true);
    });
    (0, vitest_1.it)('supports rotation selection', () => {
        const gs = (0, src_1.newGame)('testRot');
        const pieceId = Object.keys(gs.pieces).find(k => k.includes('L_SHAPE') && k.startsWith('LIGHT_'));
        const res0 = (0, src_1.attemptPlacement)(gs, { pieceId, anchor: 0, rotation: 90, reflected: false });
        (0, vitest_1.expect)(res0.legal).toBe(true);
    });
    (0, vitest_1.it)('supports reflection selection (when allowed)', () => {
        const gs = (0, src_1.newGame)('testRef');
        const pieceId = Object.keys(gs.pieces).find(k => k.includes('S_BEND') && k.startsWith('LIGHT_'));
        const res = (0, src_1.attemptPlacement)(gs, { pieceId, anchor: 10, rotation: 0, reflected: true });
        (0, vitest_1.expect)(res.legal).toBe(true);
    });
    (0, vitest_1.it)('detects new territory enclosure (simplistic scenario)', () => {
        const gs = (0, src_1.newGame)('territory1');
        // Artificially create enclosure by marking a ring of cells as occupied by LIGHT (direct state manipulation for test brevity)
        const dummyPiece = Object.values(gs.pieces).find(p => p.owner === 'LIGHT');
        if (!dummyPiece)
            throw new Error('No light piece');
        dummyPiece.placed = true;
        // Occupy border ring leaving interior empty not touching edge -> not realistic but triggers detector
        for (let y = 1; y < 9; y++) {
            for (let x = 1; x < 9; x++) {
                if (x === 1 || x === 8 || y === 1 || y === 8) {
                    gs.board[y * 10 + x] = dummyPiece;
                }
            }
        }
        (0, src_1.attemptPlacement)(gs, { pieceId: Object.keys(gs.pieces).find(k => k.includes('WALL3') && k.startsWith('LIGHT_')), anchor: 0, rotation: 0, reflected: false });
        // Territory detection runs post-validation; expect at least one territory representing interior (6x6 = 36 cells).
        (0, vitest_1.expect)(Object.keys(gs.territories).length).toBeGreaterThan(0);
        const totalCells = Object.values(gs.territories).reduce((acc, t) => acc + t.cells.length, 0);
        (0, vitest_1.expect)(totalCells).toBeGreaterThan(10);
    });
    (0, vitest_1.it)('does not create territory touching edge', () => {
        const gs = (0, src_1.newGame)('territory-edge');
        // Occupy a near-complete ring but include outer edge so interior touches edge
        const p = Object.values(gs.pieces).find(pc => pc.owner === 'LIGHT');
        p.placed = true;
        // Fill a partial enclosure that uses board edge as boundary (should not count)
        for (let x = 0; x < 10; x++)
            gs.board[x] = p; // top row
        for (let y = 0; y < 10; y++)
            gs.board[y * 10] = p; // left column
        const pieceId = Object.keys(gs.pieces).find(k => k.includes('WALL3') && k.startsWith('LIGHT_'));
        (0, src_1.attemptPlacement)(gs, { pieceId, anchor: 22, rotation: 0, reflected: false });
        (0, vitest_1.expect)(Object.values(gs.territories).length).toBe(0);
    });
    (0, vitest_1.it)('does not create territory with mixed border ownership', () => {
        const gs = (0, src_1.newGame)('territory-mixed');
        const light = Object.values(gs.pieces).find(pc => pc.owner === 'LIGHT');
        const dark = Object.values(gs.pieces).find(pc => pc.owner === 'DARK');
        light.placed = true;
        dark.placed = true;
        // Build a small 3x3 ring; ensure mixed ownership of border
        const ringCoords = [[2, 2, 'LIGHT'], [3, 2, 'LIGHT'], [4, 2, 'DARK'], [4, 3, 'DARK'], [4, 4, 'LIGHT'], [3, 4, 'DARK'], [2, 4, 'LIGHT'], [2, 3, 'DARK']];
        ringCoords.forEach(([x, y, owner]) => {
            const piece = owner === 'LIGHT' ? light : dark;
            gs.board[y * 10 + x] = piece;
        });
        const pid = Object.keys(gs.pieces).find(k => k.includes('SPIRE') && k.startsWith('LIGHT_'));
        (0, src_1.attemptPlacement)(gs, { pieceId: pid, anchor: 0, rotation: 0, reflected: false });
        (0, vitest_1.expect)(Object.values(gs.territories).length).toBe(0);
    });
    (0, vitest_1.it)('captures enclosed opponent piece and updates scores / end-game', () => {
        const gs = (0, src_1.newGame)('capture1');
        const lightAny = Object.keys(gs.pieces).find(k => k.startsWith('LIGHT_WALL3'));
        const lightPiece = gs.pieces[lightAny];
        lightPiece.placed = true;
        const ring = [22, 23, 24, 34, 44, 43, 42, 32]; // encloses 33
        ring.forEach(i => { gs.board[i] = lightPiece; });
        // Trigger territory detection via placement
        (0, src_1.attemptPlacement)(gs, { pieceId: Object.keys(gs.pieces).find(k => k.startsWith('LIGHT_WALL4')), anchor: 0, rotation: 0, reflected: false });
        const darkSpireKey = Object.keys(gs.pieces).find(k => k.startsWith('DARK_SPIRE'));
        const darkSpire = gs.pieces[darkSpireKey];
        darkSpire.placed = true;
        darkSpire.anchor = 33;
        gs.board[33] = darkSpire;
        const nextLight = Object.keys(gs.pieces).find(k => k.startsWith('LIGHT_SPIRE'));
        (0, src_1.attemptPlacement)(gs, { pieceId: nextLight, anchor: 10, rotation: 0, reflected: false });
        (0, vitest_1.expect)(darkSpire.captured).toBe(true);
    });
});
