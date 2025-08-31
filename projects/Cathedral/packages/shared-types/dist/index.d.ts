export type PlayerColor = 'LIGHT' | 'DARK';
export interface PieceShape {
    id: string;
    cells: number[][];
    area: number;
}
export interface PieceInstance {
    pieceId: string;
    owner: PlayerColor | 'NEUTRAL';
    placed: boolean;
    rotation: Rotation;
    reflected: boolean;
    anchor?: number;
    captured?: boolean;
}
export interface TerritoryRegion {
    id: string;
    owner: PlayerColor;
    cells: number[];
}
export interface GameState {
    id: string;
    turn: PlayerColor;
    board: (PieceInstance | null)[];
    pieces: Record<string, PieceInstance>;
    territories: Record<string, TerritoryRegion>;
    history: GameStateDelta[];
    cathedralPlaced: boolean;
    winner?: PlayerColor;
    scores?: Record<PlayerColor, number>;
    finished?: boolean;
}
export interface PlacementIntent {
    pieceId: string;
    anchor: number;
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
    variants: VariantShape[];
}
export interface VariantShape extends PieceShape {
    rotation: Rotation;
    reflected: boolean;
}
export type Rotation = 0 | 90 | 180 | 270;
export interface EngineConfig {
    allowReflection: boolean;
    boardSize: 10;
}
export declare const DEFAULT_ENGINE_CONFIG: EngineConfig;
export declare function cellXY(index: number): [number, number];
export declare function xyToIndex(x: number, y: number): number;
//# sourceMappingURL=index.d.ts.map