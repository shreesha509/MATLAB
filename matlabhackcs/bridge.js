// =========================================================================
// Active Suspension: BIDIRECTIONAL Node.js WebSocket Bridge
// =========================================================================
const dgram = require('dgram');
const WebSocket = require('ws');

const wss = new WebSocket.Server({ port: 8080 });
const udpServer = dgram.createSocket('udp4');
const udpClient = dgram.createSocket('udp4');

// Web → MATLAB (slider values)
wss.on('connection', (ws) => {
    console.log('Browser connected.');
    ws.on('message', (message) => {
        udpClient.send(message, 5005, '127.0.0.1');
    });
});

// MATLAB → Web (telemetry)
udpServer.on('message', (msg) => {
    wss.clients.forEach((client) => {
        if (client.readyState === WebSocket.OPEN) {
            client.send(msg.toString());
        }
    });
});

udpServer.bind(5000, () => {
    console.log('==============================================');
    console.log('  Active Suspension Bridge ACTIVE');
    console.log('  MATLAB telemetry on UDP :5000');
    console.log('  Browser sliders  on UDP :5005');
    console.log('  WebSocket server on     :8080');
    console.log('==============================================');
});
