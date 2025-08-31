import { GameState, TerritoryRegion, cellXY, xyToIndex } from '@cathedral/shared-types';

interface RegionAnalysis {
  cells: number[];
  touchesEdge: boolean;
  borderingOwners: Set<string>;
}

function exploreRegion(state: GameState, start: number, visited: boolean[]): RegionAnalysis {
  const regionCells: number[] = [];
  const stack = [start];
  visited[start] = true;
  let touchesEdge = false;
  const borderingOwners = new Set<string>();
  while (stack.length) {
    const idx = stack.pop()!;
    regionCells.push(idx);
    const [x,y] = cellXY(idx);
    if (x===0||x===9||y===0||y===9) touchesEdge = true;
    addNeighbors(state, x, y, visited, stack, borderingOwners);
  }
  return { cells: regionCells, touchesEdge, borderingOwners };
}

function addNeighbors(state: GameState, x: number, y: number, visited: boolean[], stack: number[], borderingOwners: Set<string>) {
  const neighbors: [number,number][] = [[x+1,y],[x-1,y],[x,y+1],[x,y-1]];
  for (const [nx,ny] of neighbors) {
    if (nx<0||nx>9||ny<0||ny>9) continue;
    const nIdx = xyToIndex(nx,ny);
    const occupant = state.board[nIdx];
    if (!occupant) {
      if (!visited[nIdx]) { visited[nIdx]=true; stack.push(nIdx); }
    } else if (occupant.owner !== 'NEUTRAL') {
      borderingOwners.add(occupant.owner);
    }
  }
}

function isNewRegion(state: GameState, cells: number[]): boolean {
  return !cells.some(c => Object.values(state.territories).some(t => t.cells.includes(c)));
}

// Simple flood-fill to find enclosed empty regions fully surrounded by one player's pieces and not touching edge.
export function detectNewTerritories(state: GameState): TerritoryRegion[] {
  const visited = new Array(100).fill(false);
  const regions: TerritoryRegion[] = [];
  for (let i=0;i<100;i++) {
    if (visited[i] || state.board[i]) continue;
    const { cells, touchesEdge, borderingOwners } = exploreRegion(state, i, visited);
    if (!touchesEdge && borderingOwners.size === 1 && isNewRegion(state, cells)) {
      const owner = borderingOwners.values().next().value as 'LIGHT'|'DARK';
      regions.push({ id: `T${Date.now()}_${state.history.length}_${regions.length}`, owner, cells });
    }
  }
  return regions;
}

// Capture detection: if opponent piece cells are fully enclosed inside a single player's territories after a move.
export function detectCaptures(state: GameState, player: 'LIGHT'|'DARK'): string[] {
  const opponent = player === 'LIGHT' ? 'DARK' : 'LIGHT';
  const captured: string[] = [];
  // Build a set of all territory cells owned by player
  const ownedTerritoryCells = new Set<number>();
  for (const t of Object.values(state.territories)) {
    if (t.owner === player) t.cells.forEach(c=>ownedTerritoryCells.add(c));
  }
  // Opponent pieces that have all their occupied cells inside player territory become captured.
  const occupiedCellsByPiece: Record<string, number[]> = {};
  state.board.forEach((p, idx) => {
    if (p && p.owner === opponent && !p.captured) {
      if (!occupiedCellsByPiece[p.pieceId]) occupiedCellsByPiece[p.pieceId] = [];
      occupiedCellsByPiece[p.pieceId].push(idx);
    }
  });
  for (const [pid, cells] of Object.entries(occupiedCellsByPiece)) {
    if (cells.every(c => ownedTerritoryCells.has(c))) captured.push(pid);
  }
  return captured;
}
