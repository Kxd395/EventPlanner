"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const vitest_1 = require("vitest");
const pieces_1 = require("../src/pieces");
const crypto_1 = __importDefault(require("crypto"));
function sig(cells) {
    return cells.map(c => c.join(',')).sort((a, b) => a.localeCompare(b)).join('|');
}
(0, vitest_1.describe)('shape catalog checksum', () => {
    (0, vitest_1.it)('matches expected SHA256 (update if intentional)', () => {
        const shapeStrings = pieces_1.baseShapes.slice().sort((a, b) => a.id.localeCompare(b.id)).map(s => `${s.id}:${sig(s.cells)}`);
        const combined = shapeStrings.join(';');
        const hash = crypto_1.default.createHash('sha256').update(combined).digest('hex');
        (0, vitest_1.expect)(hash).toBe('a6076ac50dc0f311aa60af5b1a022e91f53eba144338ab5fef77ce3c8b8459a1');
    });
});
