export type PlayerColor = 'LIGHT' | 'DARK';

export interface PieceShape {
  id: string;
  cells: number[][]; // array of [x,y] relative coordinates
  area: number; // number of squares
}

export interface PieceInstance {
  pieceId: string;
  owner: PlayerColor | 'NEUTRAL';
  placed: boolean;
  rotation: Rotation;
  reflected: boolean;
  anchor?: number; // top-left anchor on board if placed
  captured?: boolean; // removed from board due to capture
}

export interface TerritoryRegion {
  id: string;
  owner: PlayerColor;
  cells: number[];
}

export interface GameState {
  id: string;
  turn: PlayerColor;
  board: (PieceInstance | null)[]; // length 100
  pieces: Record<string, PieceInstance>; // keyed by piece instance id
  territories: Record<string, TerritoryRegion>;
  history: GameStateDelta[];
  cathedralPlaced: boolean;
  winner?: PlayerColor;
  scores?: Record<PlayerColor, number>;
  finished?: boolean;
}

export interface PlacementIntent {
  pieceId: string;
  anchor: number; // anchor cell index 0..99
  rotation: Rotation;
  reflected: boolean;
}

export interface GameStateDelta {
  ply: number;
  pieceId: string;
  applied: boolean;
  capturedPieceIds: string[];
  newTerritories: string[];
  scores?: Record<PlayerColor, number>;
}

export interface ValidationResult {
  legal: boolean;
  reason?: string;
  captures?: string[];
  newTerritories?: TerritoryRegion[];
}

export interface ShapeCatalogEntry extends PieceShape {
  variants: VariantShape[]; // all rotated/reflected variants
}

export interface VariantShape extends PieceShape {
  rotation: Rotation; // rotation applied from canonical base shape
  reflected: boolean; // whether a reflection was applied prior to rotation
}

export type Rotation = 0 | 90 | 180 | 270;

export interface EngineConfig {
  allowReflection: boolean;
  boardSize: 10;
}

export const DEFAULT_ENGINE_CONFIG: EngineConfig = {
  allowReflection: true,
  boardSize: 10
};

export function cellXY(index: number): [number, number] {
  return [index % 10, Math.floor(index / 10)];
}

export function xyToIndex(x: number, y: number): number {
  return y * 10 + x;
}
