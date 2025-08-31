"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.baseShapes = void 0;
exports.enumerateVariants = enumerateVariants;
exports.findVariant = findVariant;
exports.buildCatalog = buildCatalog;
exports.invalidateCatalogCache = invalidateCatalogCache;
exports.generateInitialPieces = generateInitialPieces;
const shapes_1 = require("./data/shapes");
var shapes_2 = require("./data/shapes");
Object.defineProperty(exports, "baseShapes", { enumerable: true, get: function () { return shapes_2.baseShapes; } });
function rotate(shape) {
    const rotated = shape.cells.map(([x, y]) => [y, -x]);
    // normalize so min x,y = 0
    const minX = Math.min(...rotated.map(c => c[0]));
    const minY = Math.min(...rotated.map(c => c[1]));
    const norm = rotated.map(([x, y]) => [x - minX, y - minY]);
    return { id: shape.id, cells: norm, area: shape.area };
}
function reflect(shape) {
    const reflected = shape.cells.map(([x, y]) => [-x, y]);
    const minX = Math.min(...reflected.map(c => c[0]));
    const minY = Math.min(...reflected.map(c => c[1]));
    const norm = reflected.map(([x, y]) => [x - minX, y - minY]);
    return { id: shape.id, cells: norm, area: shape.area };
}
function enumerateVariants(shape, allowReflection) {
    const variants = [];
    const baseSet = [{ s: shape, reflected: false }];
    if (allowReflection)
        baseSet.push({ s: reflect(shape), reflected: true });
    for (const { s: b, reflected } of baseSet) {
        let cur = b;
        for (let i = 0; i < 4; i++) {
            const rotation = (i * 90);
            if (!variants.some(v => isSame(v, cur))) {
                variants.push({ ...cur, rotation, reflected });
            }
            cur = rotate(cur);
        }
    }
    return variants;
}
function findVariant(entry, rotation, reflected) {
    return entry.variants.find(v => v.rotation === rotation && v.reflected === reflected);
}
function isSame(a, b) {
    if (a.cells.length !== b.cells.length)
        return false;
    const as = a.cells.map(c => c.join(',')).sort((x, y) => x.localeCompare(y));
    const bs = b.cells.map(c => c.join(',')).sort((x, y) => x.localeCompare(y));
    return as.every((v, i) => v === bs[i]);
}
let cachedCatalog = null;
function buildCatalog(allowReflection) {
    if (cachedCatalog && cachedCatalog.allowReflection === allowReflection)
        return cachedCatalog.catalog;
    const catalog = {};
    for (const shape of shapes_1.baseShapes) {
        catalog[shape.id] = { ...shape, variants: enumerateVariants(shape, allowReflection) };
    }
    cachedCatalog = { allowReflection, catalog };
    return catalog;
}
// Invalidate the cached variant catalog (use after modifying shapes or variant logic)
function invalidateCatalogCache() {
    cachedCatalog = null;
}
function generateInitialPieces() {
    const pieces = {};
    for (const shape of shapes_1.baseShapes) {
        if (shape.id === 'CATHEDRAL') {
            pieces['NEUTRAL_CATHEDRAL'] = { pieceId: 'CATHEDRAL', owner: 'NEUTRAL', placed: false, rotation: 0, reflected: false };
        }
        else {
            const idL = `LIGHT_${shape.id}`;
            const idD = `DARK_${shape.id}`;
            pieces[idL] = { pieceId: shape.id, owner: 'LIGHT', placed: false, rotation: 0, reflected: false };
            pieces[idD] = { pieceId: shape.id, owner: 'DARK', placed: false, rotation: 0, reflected: false };
        }
    }
    return pieces;
}
