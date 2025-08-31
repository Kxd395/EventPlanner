"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vitest_1 = require("vitest");
const pieces_1 = require("../src/pieces");
(0, vitest_1.describe)('authoritative shape data', () => {
    (0, vitest_1.it)('IDs are unique and area matches cell count', () => {
        const ids = new Set();
        for (const s of pieces_1.baseShapes) {
            (0, vitest_1.expect)(ids.has(s.id)).toBe(false);
            ids.add(s.id);
            (0, vitest_1.expect)(s.area).toBe(s.cells.length);
        }
    });
});
