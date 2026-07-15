#!/usr/bin/env node
import fs from 'node:fs';

const indexPath = 'app/src/main/assets/viewer/index.html';
const bridgePath = 'app/src/main/assets/viewer/app-bridge.js';
const diagnosticsPath = 'app/src/main/assets/viewer/boot-diagnostics.js';
const vendorPath = 'app/src/main/assets/viewer/vendor/molstar/molstar.js';

const index = fs.readFileSync(indexPath, 'utf8');
const bridge = fs.readFileSync(bridgePath, 'utf8');
const diagnostics = fs.readFileSync(diagnosticsPath, 'utf8');
const vendor = fs.readFileSync(vendorPath, 'utf8');

function requireMatch(condition, message) {
    if (!condition) throw new Error(message);
}

const cspMatch = index.match(/Content-Security-Policy"\s+content="([^"]+)"/s);
const csp = cspMatch ? cspMatch[1] : '';
requireMatch(csp.includes("script-src 'self'"), 'CSP must restrict scripts to the app origin');

if (vendor.includes('new Function') || vendor.includes('eval(')) {
    requireMatch(csp.includes("'unsafe-eval'"), 'Mol* bundle uses generated JavaScript; CSP must allow unsafe-eval');
}
if (vendor.includes('WebAssembly')) {
    requireMatch(
        csp.includes("'wasm-unsafe-eval'") || csp.includes("'unsafe-eval'"),
        'Mol* bundle uses WebAssembly; CSP must allow wasm evaluation',
    );
}

const diagnosticsIndex = index.indexOf('src="boot-diagnostics.js"');
const vendorIndex = index.indexOf('src="vendor/molstar/molstar.js"');
const bridgeIndex = index.indexOf('src="app-bridge.js"');
requireMatch(diagnosticsIndex >= 0, 'boot diagnostics script is missing');
requireMatch(vendorIndex > diagnosticsIndex, 'boot diagnostics must load before Mol*');
requireMatch(bridgeIndex > vendorIndex, 'host bridge must load after Mol*');
requireMatch(/#app\s*\{[^}]*position:\s*absolute;[^}]*inset:\s*0;/s.test(index), '#app must establish a full-viewport positioned container');
requireMatch(diagnostics.includes("window.addEventListener('error'"), 'global JavaScript error capture is missing');
requireMatch(diagnostics.includes("window.addEventListener('unhandledrejection'"), 'promise rejection capture is missing');
requireMatch(bridge.includes('window.molstar.Viewer.create'), 'bridge must guard and invoke the viewer API through window.molstar');
requireMatch(bridge.includes("emit('ready'"), 'bridge must expose the ready event');

console.log('Viewer shell contract passed.');
