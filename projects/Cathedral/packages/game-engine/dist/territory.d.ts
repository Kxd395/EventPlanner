import { GameState, TerritoryRegion } from '@cathedral/shared-types';
export declare function detectNewTerritories(state: GameState): TerritoryRegion[];
export declare function detectCaptures(state: GameState, player: 'LIGHT' | 'DARK'): string[];
