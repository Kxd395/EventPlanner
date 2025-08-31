import { describe, it, expect } from 'vitest';
import { enumerateVariants, baseShapes } from '../src/pieces';

const sig = (cells: number[][]) => cells.map(c=>c.join(',')).sort((a,b)=>a.localeCompare(b)).join('|');

describe('variant enumeration', () => {
  it('enumerates unique rotations (no reflection)', () => {
    for (const shape of baseShapes) {
      const vs = enumerateVariants(shape, false);
      const signatures = new Set(vs.map(v=>sig(v.cells)));
      expect(vs.length).toBe(signatures.size);
      expect(vs.length).toBeGreaterThan(0);
      expect(vs.length).toBeLessThanOrEqual(4);
    }
  });

  it('optionally includes reflected variants without duplication', () => {
    for (const shape of baseShapes) {
      const noRef = enumerateVariants(shape, false);
      const withRef = enumerateVariants(shape, true);
      const signatures = new Set(withRef.map(v=>sig(v.cells)));
      expect(withRef.length).toBe(signatures.size);
      expect(withRef.length).toBeGreaterThan(0);
      expect(withRef.length).toBeLessThanOrEqual(8);
      if (withRef.length > noRef.length) {
        expect(withRef.length).toBeGreaterThan(noRef.length);
      }
    }
  });
});
