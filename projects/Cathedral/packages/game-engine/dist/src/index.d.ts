import { GameState, PlacementIntent, ValidationResult, EngineConfig } from '@cathedral/shared-types';
import { generateInitialPieces } from './pieces';
export declare function newGame(id?: string, _config?: EngineConfig): GameState;
export declare function attemptPlacement(state: GameState, intent: PlacementIntent): ValidationResult;
export { generateInitialPieces };
