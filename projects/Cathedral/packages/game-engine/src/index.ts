import { GameState, PlacementIntent, ValidationResult, DEFAULT_ENGINE_CONFIG, EngineConfig, PieceInstance } from '@cathedral/shared-types';
import { generateInitialPieces } from './pieces';
import { validatePlacement } from './validate';
import { applyPlacement } from './mutate';

let gameCounter = 0;
export function newGame(id?: string, _config: EngineConfig = DEFAULT_ENGINE_CONFIG): GameState {
  const gameId = id ?? `game_${Date.now()}_${++gameCounter}`;
  const board: (PieceInstance | null)[] = Array(100).fill(null);
  const pieces = generateInitialPieces();
  return {
    id: gameId,
    turn: 'LIGHT',
    board,
    pieces,
    territories: {},
    history: [],
  cathedralPlaced: false,
  scores: { LIGHT: 0, DARK: 0 },
  finished: false
  };
}

export function attemptPlacement(state: GameState, intent: PlacementIntent): ValidationResult {
  const validation = validatePlacement(state, intent);
  if (!validation.legal) return validation;
  applyPlacement(state, intent, validation);
  return validation;
}

export { generateInitialPieces };
