"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.DEFAULT_ENGINE_CONFIG = void 0;
exports.cellXY = cellXY;
exports.xyToIndex = xyToIndex;
exports.DEFAULT_ENGINE_CONFIG = {
    allowReflection: true,
    boardSize: 10
};
function cellXY(index) {
    return [index % 10, Math.floor(index / 10)];
}
function xyToIndex(x, y) {
    return y * 10 + x;
}
