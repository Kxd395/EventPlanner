"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
const vitest_1 = require("vitest");
const pieces_1 = require("../src/pieces");
const sig = (cells) => cells.map(c => c.join(',')).sort((a, b) => a.localeCompare(b)).join('|');
(0, vitest_1.describe)('variant enumeration', () => {
    (0, vitest_1.it)('enumerates unique rotations (no reflection)', () => {
        for (const shape of pieces_1.baseShapes) {
            const vs = (0, pieces_1.enumerateVariants)(shape, false);
            const signatures = new Set(vs.map(v => sig(v.cells)));
            (0, vitest_1.expect)(vs.length).toBe(signatures.size);
            (0, vitest_1.expect)(vs.length).toBeGreaterThan(0);
            (0, vitest_1.expect)(vs.length).toBeLessThanOrEqual(4);
        }
    });
    (0, vitest_1.it)('optionally includes reflected variants without duplication', () => {
        for (const shape of pieces_1.baseShapes) {
            const noRef = (0, pieces_1.enumerateVariants)(shape, false);
            const withRef = (0, pieces_1.enumerateVariants)(shape, true);
            const signatures = new Set(withRef.map(v => sig(v.cells)));
            (0, vitest_1.expect)(withRef.length).toBe(signatures.size);
            (0, vitest_1.expect)(withRef.length).toBeGreaterThan(0);
            (0, vitest_1.expect)(withRef.length).toBeLessThanOrEqual(8);
            if (withRef.length > noRef.length) {
                (0, vitest_1.expect)(withRef.length).toBeGreaterThan(noRef.length);
            }
        }
    });
});
