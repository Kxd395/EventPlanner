// Simple development WebSocket client to verify the gateway is running.
import WebSocket from 'ws';

const url = process.env.WS_URL || 'ws://localhost:8080';
console.log('[client] connecting to', url);

const ws = new WebSocket(url);

ws.on('open', () => {
  console.log('[client] connection open');
});

ws.on('message', (data) => {
  try {
    const msg = JSON.parse(data.toString());
    console.log('[client] received', msg);
  } catch {
    console.log('[client] raw message', data.toString());
  }
});

ws.on('error', (err) => {
  console.error('[client] error', err);
});

ws.on('close', () => {
  console.log('[client] connection closed');
});
