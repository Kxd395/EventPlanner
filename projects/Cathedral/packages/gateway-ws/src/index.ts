import { WebSocketServer } from 'ws';
import { newGame } from '@cathedral/game-engine';
import { GameState } from '@cathedral/shared-types';
import http from 'http';

const START_PORT = Number(process.env.PORT || 8080);
const MAX_FALLBACKS = Number(process.env.PORT_FALLBACKS || 5);

let activePort = START_PORT;
let httpServer: http.Server | null = null;
let wss: WebSocketServer | null = null;
let connectionCount = 0;

// Maintain a single shared game so all clients see same board
import type { GameState as GS } from '@cathedral/shared-types';
let globalGame: GS | null = null;

function initGlobalGame() {
  if (globalGame) return;
  globalGame = newGame('global');
  placeDemoIfEmpty(globalGame);
  console.log('[gateway] global game initialized with demo placements');
}

function placeDemoIfEmpty(state: GS) {
  // If any board cell occupied, skip
  if (state.board.some(c => c)) return;
  // Demo placement for Cathedral (neutral) and a LIGHT bishop
  const cathedral = state.pieces['NEUTRAL_CATHEDRAL'];
  const bishop = state.pieces['LIGHT_BISHOP'];
  if (cathedral && bishop) {
    // Cathedral shape (from shapes.ts): [[0,0],[1,0],[0,1],[1,1],[2,1]] at anchor (3,3)
    const anchorCat = 3 + 3 * 10; // index 33
    const catCells = [[0,0],[1,0],[0,1],[1,1],[2,1]];
    cathedral.placed = true; cathedral.anchor = anchorCat;
    for (const [dx,dy] of catCells) {
      const idx = anchorCat + dx + dy * 10;
      if (idx >=0 && idx < state.board.length) state.board[idx] = cathedral;
    }
    // Bishop shape: [[0,0],[1,0],[0,1],[0,2]] at anchor (0,0)
    const anchorB = 0;
    const bishopCells = [[0,0],[1,0],[0,1],[0,2]];
    bishop.placed = true; bishop.anchor = anchorB;
    for (const [dx,dy] of bishopCells) {
      const idx = anchorB + dx + dy * 10;
      if (idx >=0 && idx < state.board.length) state.board[idx] = bishop;
    }
  }
}

// Enhanced HTML dev/debug page with obvious board visibility
const PAGE_VERSION = 'v0.4-websocket-debug';
const HTML_PAGE = `<!DOCTYPE html><html><head><meta charset="utf-8"/>
<title>Cathedral Gateway</title>
<style>
body{font-family:system-ui,Arial;margin:2rem;background:#111;color:#eee}
code{background:#222;padding:2px 4px;border-radius:4px}
#log{white-space:pre-wrap;font:12px/1.45 monospace;background:#000;border:1px solid #333;padding:8px;max-height:180px;overflow:auto;margin-top:1rem}
button{background:#333;color:#eee;border:1px solid #555;padding:6px 12px;border-radius:4px;cursor:pointer;margin-right:.5rem}
button:hover{background:#444}
.status{display:inline-block;padding:2px 6px;border-radius:4px;background:#444;margin-left:.5rem;font:12px/1 monospace}
#board{margin:.5rem 0;border:2px solid #555;display:inline-block;padding:4px}
#board div{width:32px;height:32px;display:flex;align-items:center;justify-content:center;font:bold 14px/1 monospace;border:1px solid #444;background:#1a1a1a;transition:all .2s ease}
#board div.occupied{border:2px solid #666;font-size:16px;font-weight:bold;text-shadow:0 0 3px currentColor}
.legend{margin:.5rem 0;font:12px/1.4 monospace}
.legend span{display:inline-block;width:20px;height:20px;margin:0 4px 0 0;text-align:center;line-height:20px;border:1px solid #666;font-weight:bold}
</style></head><body>
<h1>Cathedral Gateway <small style="font-size:.5em;opacity:.6">${PAGE_VERSION}</small></h1>
<p>WebSocket endpoint: <code id="ep">(starting)</code><span id="wsStatus" class="status">init</span></p>
<p><button id="btnPing">Ping</button><button id="btnClear">Clear Log</button><button id="btnRefresh">Refresh State</button></p>
<div id="hud" style="margin:1rem 0;display:flex;gap:2rem;flex-wrap:wrap">
  <div><strong>Scores</strong><br/><span id="scoreLight">LIGHT: 0</span><br/><span id="scoreDark">DARK: 0</span></div>
  <div><strong>Turn</strong><br/><span id="turn">(n/a)</span></div>
  <div><strong>Pieces</strong><br/><span id="piecesLight">LIGHT pieces: 0</span><br/><span id="piecesDark">DARK pieces: 0</span></div>
  <div><strong>Board</strong><br/><span id="occupied">occupied: 0</span><br/><span id="lastUpdate">last update: never</span></div>
</div>
<div class="legend">
  <strong>Legend:</strong>
  <span style="background:#3af;color:#000">L</span>LIGHT
  <span style="background:#f53;color:#000">D</span>DARK  
  <span style="background:#aaa;color:#000">N</span>NEUTRAL
  <span style="background:#555;color:#222">X</span>CAPTURED
</div>
<div id="board" style="display:grid;grid-template-columns:repeat(10,32px);grid-auto-rows:32px;gap:1px"></div>
<div id="log" aria-live="polite"></div>
<script>
const logBox=document.getElementById('log');
function log(line){
  const ts=new Date().toISOString().split('T')[1].replace('Z','');
  logBox.textContent+='['+ts+'] '+line+'\n';
  logBox.scrollTop=logBox.scrollHeight;
}
const statusEl=document.getElementById('wsStatus');
function setStatus(s){statusEl.textContent=s;}
const host=location.host;
document.getElementById('ep').textContent='ws://'+host+'/';
const boardEl=document.getElementById('board');

// Pre-render empty grid with clear styling
for(let i=0;i<100;i++){
  const cell=document.createElement('div');
  cell.style.opacity=.3;
  cell.textContent='·';
  cell.title='#'+i+' (empty)';
  boardEl.appendChild(cell);
} 
log('Pre-rendered 10x10 grid');

function renderBoard(state){
  if(!state||!Array.isArray(state.board)) {
    log('No valid board state to render');
    return;
  }
  
  boardEl.textContent='';
  const cells=state.board;
  let occupied=0;
  
  for(let i=0;i<cells.length;i++){
    const c=document.createElement('div');
    const v=cells[i];
    c.title = '#'+i;
    
    if(v){
      occupied++;
      c.className = 'occupied';
      let ownerColor='#f53';
      let label='D';
      
      if(v.owner==='LIGHT'){
        ownerColor='#3af';
        label='L';
      } else if(v.owner==='NEUTRAL'){
        ownerColor='#aaa';
        label='N';
      }
      
      c.style.background=ownerColor;
      c.style.color='#000';
      c.textContent=label;
      c.title += ' ('+v.owner+')';
      
      if(v.captured){
        c.style.background='#555';
        c.style.color='#222';
        c.title+=' CAPTURED';
        c.textContent='X';
      }
    } else {
      c.style.opacity=.2;
      c.textContent='·';
      c.title += ' (empty)';
    }
    
    boardEl.appendChild(c);
  }
  
  document.getElementById('occupied').textContent='occupied: '+occupied;
  document.getElementById('lastUpdate').textContent='last update: '+new Date().toLocaleTimeString();
  
  if(!occupied){
    log('Board rendered but empty (no placements yet)');
  } else {
    log('Board rendered with '+occupied+' occupied cells');
  }
}

function updateHud(state){
  if(!state) return;
  
  document.getElementById('turn').textContent=state.turn+(state.finished?' (finished)':'');
  
  if(state.scores){
    document.getElementById('scoreLight').textContent='LIGHT: '+state.scores.LIGHT;
    document.getElementById('scoreDark').textContent='DARK: '+state.scores.DARK;
  }
  
  const lightPieces=Object.values(state.pieces).filter(p=>p.owner==='LIGHT').length;
  const darkPieces=Object.values(state.pieces).filter(p=>p.owner==='DARK').length;
  document.getElementById('piecesLight').textContent='LIGHT pieces: '+lightPieces;
  document.getElementById('piecesDark').textContent='DARK pieces: '+darkPieces;
}

let latestState=null;
let ws;

function connect(){
  setStatus('connecting');
  const wsUrl=(location.protocol==='https:'?'wss://':'ws://')+host;
  log('Attempting WebSocket connection to: '+wsUrl);
  ws=new WebSocket(wsUrl);
  
  const reqTimer=setTimeout(()=>{
    if(!latestState && ws.readyState===1){
      log('No state yet after 1.2s; requesting snapshot');
      ws.send(JSON.stringify({type:'req_state'}));
    }
  },1200);
  
  ws.onopen=()=>{
    log('✓ WebSocket connection opened successfully');
    setStatus('open');
  };
  
  ws.onmessage=e=>{
    log('Received: '+e.data.substring(0,100)+(e.data.length>100?'...':''));
    try{
      const msg=JSON.parse(e.data);
      if(msg.type==='state'){
        latestState=msg.state;
        renderBoard(latestState);
        updateHud(latestState);
        log('✓ State applied - ID: '+msg.state.id);
      }
    }catch(err){
      log('✗ JSON parse error: '+err.message);
    }
  };
  
  ws.onclose=(event)=>{
    clearTimeout(reqTimer);
    log('✗ WebSocket closed (code: '+event.code+', reason: '+event.reason+'), retrying in 2s');
    setStatus('closed');
    setTimeout(connect,2000);
  };
  
  ws.onerror=e=>{
    log('✗ WebSocket error - check console for details');
    console.error('WebSocket Error Details:',e);
    setStatus('error');
  };
}

connect();

// Button handlers
const pingBtn=document.getElementById('btnPing');
pingBtn.onclick=()=>{
  if(ws&&ws.readyState===1){
    ws.send(JSON.stringify({type:'ping',clientTs:Date.now()}));
    log('Sent ping');
  }else{
    log('Cannot ping (socket not open)');
  }
};

const clearBtn=document.getElementById('btnClear');
clearBtn.onclick=()=>{
  logBox.textContent='';
  log('Log cleared');
};

const refreshBtn=document.getElementById('btnRefresh');
refreshBtn.onclick=()=>{
  if(ws&&ws.readyState===1){
    ws.send(JSON.stringify({type:'req_state'}));
    log('Requested fresh state');
  }else{
    log('Cannot refresh (socket not open)');
  }
};
</script></body></html>`;

// Completely fresh debug page to bypass all caching
const FRESH_DEBUG_PAGE = `<!DOCTYPE html>
<html><head><meta charset="utf-8"/>
<title>Cathedral Board - FRESH ${Date.now()}</title>
<style>
body{font-family:Arial;margin:20px;background:#000;color:#0f0}
h1{color:#ff0}
#log{background:#111;color:#0f0;padding:10px;height:200px;overflow:auto;font-family:monospace;border:2px solid #0f0}
#board{display:grid;grid-template-columns:repeat(10,40px);gap:2px;margin:20px 0}
.cell{width:40px;height:40px;border:2px solid #333;background:#111;color:#fff;font-weight:bold;display:flex;align-items:center;justify-content:center}
.occupied{background:#f00;color:#fff;border-color:#ff0}
button{background:#333;color:#0f0;border:1px solid #0f0;padding:10px;margin:5px}
</style>
</head><body>
<h1>CATHEDRAL BOARD DEBUG - ${Date.now()}</h1>
<div id="status">Status: <span id="wsStatus">STARTING</span></div>
<button onclick="testWS()">Test WebSocket</button>
<button onclick="clearLog()">Clear Log</button>
<div id="log"></div>
<div id="board"></div>
<script>
const log = document.getElementById('log');
const status = document.getElementById('wsStatus');
const board = document.getElementById('board');

function addLog(msg) {
  const time = new Date().toLocaleTimeString();
  log.innerHTML += '[' + time + '] ' + msg + '<br>';
  log.scrollTop = log.scrollHeight;
}

function clearLog() {
  log.innerHTML = '';
}

function testWS() {
  addLog('TESTING WebSocket connection...');
  status.textContent = 'CONNECTING';
  
  const ws = new WebSocket('ws://localhost:8080');
  
  ws.onopen = function() {
    addLog('SUCCESS: WebSocket opened!');
    status.textContent = 'CONNECTED';
  };
  
  ws.onmessage = function(event) {
    addLog('RECEIVED: ' + event.data.substring(0, 100));
    try {
      const data = JSON.parse(event.data);
      if (data.type === 'state' && data.state && data.state.board) {
        renderBoard(data.state.board);
      }
    } catch(e) {
      addLog('Parse error: ' + e.message);
    }
  };
  
  ws.onclose = function(event) {
    addLog('CLOSED: Code=' + event.code + ' Reason=' + event.reason);
    status.textContent = 'CLOSED';
  };
  
  ws.onerror = function(error) {
    addLog('ERROR: WebSocket failed to connect');
    console.error('WebSocket error:', error);
    status.textContent = 'ERROR';
  };
}

function renderBoard(boardData) {
  board.innerHTML = '';
  for (let i = 0; i < 100; i++) {
    const cell = document.createElement('div');
    cell.className = 'cell';
    cell.textContent = i;
    if (boardData[i]) {
      cell.className += ' occupied';
      cell.textContent = boardData[i].name ? boardData[i].name.charAt(0) : 'X';
    }
    board.appendChild(cell);
  }
  addLog('Board rendered with ' + boardData.filter(Boolean).length + ' pieces');
}

addLog('Page loaded. Click Test WebSocket to start.');
testWS(); // Auto-start the test
</script>
</body></html>`;

function createServers(port: number) {
  httpServer = http.createServer((req, res) => {
    if (!req.url) { res.statusCode = 400; return res.end('Bad request'); }
    if (req.url === '/' || req.url.startsWith('/index') || req.url.startsWith('/debug') || req.url.startsWith('/board')) {
      res.setHeader('content-type', 'text/html; charset=utf-8');
      res.setHeader('cache-control', 'no-cache, no-store, must-revalidate, max-age=0');
      res.setHeader('pragma', 'no-cache');
      res.setHeader('expires', '0');
      return res.end(HTML_PAGE);
    }
    if (req.url === '/fresh') {
      res.setHeader('content-type', 'text/html; charset=utf-8');
      res.setHeader('cache-control', 'no-cache, no-store, must-revalidate, max-age=0');
      res.setHeader('pragma', 'no-cache');
      res.setHeader('expires', '0');
      return res.end(FRESH_DEBUG_PAGE);
    }
    if (req.url === '/health') {
      res.setHeader('content-type', 'application/json');
      return res.end(JSON.stringify({ status: 'ok', port: activePort, uptime: process.uptime(), connections: connectionCount }));
    }
    res.statusCode = 404; res.end('Not found');
  });

  wss = new WebSocketServer({ server: httpServer });
  wss.on('connection', (ws: import('ws').WebSocket) => {
    connectionCount++;
    initGlobalGame();
    const game = globalGame!;
    ws.send(JSON.stringify({ type: 'hello', gameId: game.id }));
    ws.send(JSON.stringify({ type: 'state', state: snapshot(game) }));
    console.log('[gateway] client connected; sent hello/state for global game', game.id, 'connections=', connectionCount);
    ws.on('message', raw => {
      try {
        const msg = JSON.parse(raw.toString());
        if (msg.type === 'ping') {
          ws.send(JSON.stringify({ type: 'pong', serverTs: Date.now(), echo: msg.clientTs }));
        } else if (msg.type === 'req_state') {
          if (globalGame) ws.send(JSON.stringify({ type: 'state', state: snapshot(globalGame) }));
        }
      } catch { /* ignore malformed */ }
    });
    ws.on('close', () => {
      connectionCount = Math.max(0, connectionCount - 1);
      console.log('[gateway] client disconnected connections=', connectionCount);
    });
  });

  httpServer.on('listening', () => {
    console.log('==========================================');
    console.log(' Cathedral Gateway running');
    console.log(' HTTP  : http://localhost:' + activePort + '/');
    console.log(' Health: http://localhost:' + activePort + '/health');
    console.log(' WS    : ws://localhost:' + activePort + '/');
    console.log('==========================================');
  });

  httpServer.on('error', (err: any) => {
    if (err.code === 'EADDRINUSE') {
      if (port === START_PORT) console.warn(`[gateway] Port ${port} in use.`);
      if (port - START_PORT < MAX_FALLBACKS) {
        const next = port + 1;
        console.log(`[gateway] Trying fallback port ${next}...`);
        setTimeout(() => start(next), 100);
      } else {
        console.error('[gateway] Exhausted fallback ports. Abort.');
        process.exit(1);
      }
    } else {
      console.error('[gateway] HTTP server error', err);
    }
  });
}

function start(port: number) {
  activePort = port;
  createServers(port);
  httpServer!.listen(port);
}

start(START_PORT);

process.on('SIGINT', () => {
  console.log('\n[gateway] shutting down');
  wss?.close();
  httpServer?.close(() => process.exit(0));
});

function projectBoard(state: GameState) {
  return state.board.map(cell => cell ? { owner: cell.owner, captured: !!cell.captured } : null);
}
function snapshot(state: GameState) {
  return { id: state.id, turn: state.turn, board: projectBoard(state), pieces: state.pieces, scores: state.scores, finished: state.finished };
}
