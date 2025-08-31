import { describe, it, expect } from 'vitest';
import { baseShapes } from '../src/pieces';
import crypto from 'crypto';

function sig(cells: number[][]) {
  return cells.map(c=>c.join(',')).sort((a,b)=>a.localeCompare(b)).join('|');
}

describe('shape catalog checksum', () => {
  it('matches expected SHA256 (update if intentional)', () => {
    const shapeStrings = baseShapes.slice().sort((a,b)=>a.id.localeCompare(b.id)).map(s=>`${s.id}:${sig(s.cells)}`);
    const combined = shapeStrings.join(';');
    const hash = crypto.createHash('sha256').update(combined).digest('hex');
    expect(hash).toBe('a6076ac50dc0f311aa60af5b1a022e91f53eba144338ab5fef77ce3c8b8459a1');
  });
});
