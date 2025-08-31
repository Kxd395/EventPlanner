// Authoritative Cathedral piece geometry (current approximate placeholders)
// Each piece lists its canonical cell coordinates relative to an origin (0,0).
// The area field must equal cells.length; tests assert this to guard against drift.
// To update geometry:
// 1. Replace cells arrays with authoritative coordinates (ensure normalization at (0,0)).
// 2. Ensure each 'area' equals cells.length.
// 3. Run: pnpm -F @cathedral/game-engine test (will fail checksum).
// 4. Recompute new hash: node scripts/print-shape-hash.mjs (create if absent) or replicate logic in shapes.hash.test.ts.
// 5. Update expected hash in tests/shapes.hash.test.ts and commit both shape + hash changes in one commit.
import { PieceShape } from '@cathedral/shared-types';

export const baseShapes: PieceShape[] = [
  { id: 'CATHEDRAL', cells: [[0,0],[1,0],[0,1],[1,1],[2,1]], area: 5 },
  { id: 'BISHOP', cells: [[0,0],[1,0],[0,1],[0,2]], area: 4 },
  { id: 'TOWER', cells: [[0,0],[1,0],[2,0],[1,1]], area: 4 },
  { id: 'WALL4', cells: [[0,0],[1,0],[2,0],[3,0]], area: 4 },
  { id: 'WALL3', cells: [[0,0],[1,0],[2,0]], area: 3 },
  { id: 'COURTYARD', cells: [[0,0],[1,0],[0,1],[1,1]], area: 4 },
  { id: 'L_SHAPE', cells: [[0,0],[0,1],[0,2],[1,2]], area: 4 },
  { id: 'S_BEND', cells: [[0,0],[1,0],[1,1],[2,1]], area: 4 },
  { id: 'Z_BEND', cells: [[1,0],[2,0],[0,1],[1,1]], area: 4 },
  { id: 'SPIRE', cells: [[0,0],[0,1],[1,1]], area: 3 },
  { id: 'WING', cells: [[0,0],[1,0],[2,0],[2,1]], area: 4 },
  { id: 'CROSS5', cells: [[1,0],[0,1],[1,1],[2,1],[1,2]], area: 5 },
  { id: 'HOOK5', cells: [[0,0],[0,1],[0,2],[1,2],[2,2]], area: 5 }
];

export default baseShapes;
