import { PieceInstance, PieceShape, ShapeCatalogEntry, VariantShape, Rotation } from '@cathedral/shared-types';
import { baseShapes } from './data/shapes';
export { baseShapes } from './data/shapes';

function rotate(shape: PieceShape): PieceShape {
  const rotated = shape.cells.map(([x,y]) => [y, -x] as [number, number]);
  // normalize so min x,y = 0
  const minX = Math.min(...rotated.map(c=>c[0]));
  const minY = Math.min(...rotated.map(c=>c[1]));
  const norm = rotated.map(([x,y]) => [x - minX, y - minY]);
  return { id: shape.id, cells: norm, area: shape.area };
}

function reflect(shape: PieceShape): PieceShape {
  const reflected = shape.cells.map(([x,y]) => [-x, y] as [number, number]);
  const minX = Math.min(...reflected.map(c=>c[0]));
  const minY = Math.min(...reflected.map(c=>c[1]));
  const norm = reflected.map(([x,y]) => [x - minX, y - minY]);
  return { id: shape.id, cells: norm, area: shape.area };
}

export function enumerateVariants(shape: PieceShape, allowReflection: boolean): VariantShape[] {
  const variants: VariantShape[] = [];
  const baseSet: { s: PieceShape; reflected: boolean }[] = [ { s: shape, reflected: false } ];
  if (allowReflection) baseSet.push({ s: reflect(shape), reflected: true });
  for (const { s: b, reflected } of baseSet) {
    let cur = b;
    for (let i=0;i<4;i++) {
      const rotation: Rotation = (i * 90) as Rotation;
      if (!variants.some(v => isSame(v, cur))) {
        variants.push({ ...cur, rotation, reflected });
      }
      cur = rotate(cur);
    }
  }
  return variants;
}

export function findVariant(entry: ShapeCatalogEntry, rotation: Rotation, reflected: boolean): VariantShape | undefined {
  return entry.variants.find(v => v.rotation === rotation && v.reflected === reflected);
}

function isSame(a: PieceShape, b: PieceShape): boolean {
  if (a.cells.length !== b.cells.length) return false;
  const as = a.cells.map(c=>c.join(',')).sort((x,y)=>x.localeCompare(y));
  const bs = b.cells.map(c=>c.join(',')).sort((x,y)=>x.localeCompare(y));
  return as.every((v,i)=>v===bs[i]);
}

let cachedCatalog: { allowReflection: boolean; catalog: Record<string, ShapeCatalogEntry> } | null = null;
export function buildCatalog(allowReflection: boolean): Record<string, ShapeCatalogEntry> {
  if (cachedCatalog && cachedCatalog.allowReflection === allowReflection) return cachedCatalog.catalog;
  const catalog: Record<string, ShapeCatalogEntry> = {};
  for (const shape of baseShapes) {
    catalog[shape.id] = { ...shape, variants: enumerateVariants(shape, allowReflection) };
  }
  cachedCatalog = { allowReflection, catalog };
  return catalog;
}

// Invalidate the cached variant catalog (use after modifying shapes or variant logic)
export function invalidateCatalogCache() {
  cachedCatalog = null;
}

export function generateInitialPieces(): Record<string, PieceInstance> {
  const pieces: Record<string, PieceInstance> = {};
  for (const shape of baseShapes) {
    if (shape.id === 'CATHEDRAL') {
      pieces['NEUTRAL_CATHEDRAL'] = { pieceId: 'CATHEDRAL', owner: 'NEUTRAL', placed: false, rotation: 0, reflected: false };
    } else {
      const idL = `LIGHT_${shape.id}`;
      const idD = `DARK_${shape.id}`;
      pieces[idL] = { pieceId: shape.id, owner: 'LIGHT', placed: false, rotation: 0, reflected: false };
      pieces[idD] = { pieceId: shape.id, owner: 'DARK', placed: false, rotation: 0, reflected: false };
    }
  }
  return pieces;
}
