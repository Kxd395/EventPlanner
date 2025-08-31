import { describe, it, expect } from 'vitest';
import { baseShapes } from '../src/pieces';

describe('authoritative shape data', () => {
  it('IDs are unique and area matches cell count', () => {
    const ids = new Set<string>();
    for (const s of baseShapes) {
      expect(ids.has(s.id)).toBe(false);
      ids.add(s.id);
      expect(s.area).toBe(s.cells.length);
    }
  });
});
