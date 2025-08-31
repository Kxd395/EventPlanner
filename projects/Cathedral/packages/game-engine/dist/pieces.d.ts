import { PieceInstance, PieceShape, ShapeCatalogEntry, VariantShape, Rotation } from '@cathedral/shared-types';
export { baseShapes } from './data/shapes';
export declare function enumerateVariants(shape: PieceShape, allowReflection: boolean): VariantShape[];
export declare function findVariant(entry: ShapeCatalogEntry, rotation: Rotation, reflected: boolean): VariantShape | undefined;
export declare function buildCatalog(allowReflection: boolean): Record<string, ShapeCatalogEntry>;
export declare function invalidateCatalogCache(): void;
export declare function generateInitialPieces(): Record<string, PieceInstance>;
