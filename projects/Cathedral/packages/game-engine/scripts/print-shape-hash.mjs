#!/usr/bin/env node
import crypto from 'crypto';
import fs from 'fs';
import path from 'path';

// Lightweight extraction: require that shapes.ts exports const baseShapes = [...];
// We parse the file to avoid needing a TS runtime.
const shapesTsPath = path.resolve(process.cwd(), 'src/data/shapes.ts');
const content = fs.readFileSync(shapesTsPath,'utf8');
const match = content.match(/export const baseShapes:.*?=\s*(\[[\s\S]*?\n\]);/);
if(!match) {
	console.error('Could not locate baseShapes array in shapes.ts');
	process.exit(1);
}
// Naive JSON-ish transform: remove trailing comments and 'area:' duplication kept.
let arrayText = match[1]
	.replace(/([a-zA-Z0-9_]+):/g,'"$1":')
	.replace(/'(.*?)'/g,'"$1"');
// Remove potential trailing commas before ]
arrayText = arrayText.replace(/,\s*]/g,']');
let baseShapes;
try { baseShapes = JSON.parse(arrayText); } catch(e){
	console.error('Failed to parse baseShapes:', e.message);
	process.exit(1);
}

function sig(cells){return cells.map(c=>c.join(',')).sort((a,b)=>a.localeCompare(b)).join('|');}
const shapeStrings = baseShapes.slice().sort((a,b)=>a.id.localeCompare(b.id)).map(s=>`${s.id}:${sig(s.cells)}`);
const combined = shapeStrings.join(';');
const hash = crypto.createHash('sha256').update(combined).digest('hex');
console.log('Combined Shape Signature:');
console.log(combined);
console.log('SHA256:', hash);
