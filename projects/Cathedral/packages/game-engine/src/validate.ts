import { GameState, PlacementIntent, ValidationResult, cellXY, xyToIndex } from '@cathedral/shared-types';
import { buildCatalog, findVariant } from './pieces';
import { detectNewTerritories, detectCaptures } from './territory';

const catalog = buildCatalog(true);

export function validatePlacement(state: GameState, intent: PlacementIntent): ValidationResult {
  const piece = state.pieces[intent.pieceId];
  if (!piece) return { legal: false, reason: 'UNKNOWN_PIECE' };
  if (piece.placed) return { legal: false, reason: 'ALREADY_PLACED' };
  if (intent.anchor < 0 || intent.anchor >= state.board.length) return { legal: false, reason: 'OUT_OF_BOUNDS' };

  const shapeEntry = catalog[piece.pieceId];
  if (!shapeEntry) return { legal: false, reason: 'SHAPE_NOT_FOUND' };
  const variant = findVariant(shapeEntry, intent.rotation, intent.reflected) || shapeEntry.variants[0];
  const [ax, ay] = cellXY(intent.anchor);
  for (const [dx,dy] of variant.cells) {
    const x = ax + dx;
    const y = ay + dy;
    if (x < 0 || x >= 10 || y < 0 || y >= 10) return { legal:false, reason:'OUT_OF_BOUNDS' };
    const idx = xyToIndex(x,y);
    if (state.board[idx]) return { legal:false, reason:'CELL_OCCUPIED' };
  }
  // Basic territory detection (captures still not implemented)
  const newT = detectNewTerritories(state);
  const captures = detectCaptures(state, piece.owner as 'LIGHT'|'DARK');
  return { legal: true, captures, newTerritories: newT };
}
