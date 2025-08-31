import { GameState, PlacementIntent, ValidationResult, cellXY, xyToIndex } from '@cathedral/shared-types';
import { buildCatalog, findVariant } from './pieces';

const catalog = buildCatalog(true);

export function applyPlacement(state: GameState, intent: PlacementIntent, validation: ValidationResult) {
  const piece = state.pieces[intent.pieceId];
  piece.placed = true;
  piece.anchor = intent.anchor;
  piece.rotation = intent.rotation;
  piece.reflected = intent.reflected;
  // Fill board cells using orientation
  const entry = catalog[piece.pieceId];
  const variant = findVariant(entry, piece.rotation, piece.reflected) || entry.variants[0];
  const [ax, ay] = cellXY(piece.anchor as number);
  for (const [dx,dy] of variant.cells) {
    const idx = xyToIndex(ax+dx, ay+dy);
    state.board[idx] = piece;
  }
  // Apply captures: remove opponent pieces
  processCaptures(state, piece.owner as 'LIGHT'|'DARK', validation.captures);
  // Update scores (simple: territory cells + placed piece areas - captured pieces areas)
  state.scores = recomputeScores(state);
  // End-game detection: all pieces placed or no legal moves (simplified: all non-captured pieces placed)
  detectEndGame(state);
  // History append (simplified)
  // Persist new territories
  for (const t of validation.newTerritories || []) {
    state.territories[t.id] = t;
  }
  state.history.push({
    ply: state.history.length + 1,
    pieceId: intent.pieceId,
    applied: true,
    capturedPieceIds: validation.captures || [],
    newTerritories: (validation.newTerritories || []).map(t => t.id),
    scores: state.scores
  });
  state.turn = state.turn === 'LIGHT' ? 'DARK' : 'LIGHT';
}

function processCaptures(state: GameState, player: 'LIGHT'|'DARK', captures?: string[]) {
  if (!captures?.length) return;
  for (const pid of captures) {
    for (let i=0;i<state.board.length;i++) {
      const occ = state.board[i];
      if (occ && occ.pieceId === pid && occ.owner !== player) {
        occ.captured = true;
        state.board[i] = null;
      }
    }
  }
}

function recomputeScores(state: GameState) {
  return {
    LIGHT: computeScore(state, 'LIGHT'),
    DARK: computeScore(state, 'DARK')
  };
}

function detectEndGame(state: GameState) {
  if (state.finished) return;
  const remaining = Object.values(state.pieces).filter(p=>p.owner!=='NEUTRAL' && !p.captured && !p.placed);
  if (remaining.length) return;
  state.finished = true;
  const { LIGHT, DARK } = state.scores || { LIGHT:0, DARK:0 };
  if (LIGHT !== DARK) state.winner = LIGHT > DARK ? 'LIGHT' : 'DARK';
}

function computeScore(state: GameState, player: 'LIGHT'|'DARK'): number {
  // Sum areas of placed pieces not captured + territory cell count
  const territoryCells = Object.values(state.territories).filter(t=>t.owner===player).reduce((a,t)=>a+t.cells.length,0);
  const pieceArea = Object.values(state.pieces).filter(p=>p.owner===player && p.placed && !p.captured).reduce((a,p)=>a + lookupArea(p.pieceId),0);
  return territoryCells + pieceArea;
}

function lookupArea(pieceId: string): number {
  // crude mapping fallback: infer from catalog if available
  const entry = catalog[pieceId];
  return entry ? entry.area : 0;
}
