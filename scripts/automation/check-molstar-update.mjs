#!/usr/bin/env node
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';

const args = process.argv.slice(2);
let target = null;
let output = null;
for (let i = 0; i < args.length; i += 1) {
    if (args[i] === '--target') target = args[++i];
    else if (args[i] === '--output') output = args[++i];
    else throw new Error(`Unknown argument: ${args[i]}`);
}
const current = fs.readFileSync('app/src/main/assets/viewer/vendor/molstar/VERSION', 'utf8').trim();
if (!target) {
    const raw = execFileSync('npm', ['view', 'molstar', 'dist-tags.latest', '--json'], {
        encoding: 'utf8',
        stdio: ['ignore', 'pipe', 'inherit'],
    });
    target = JSON.parse(raw);
}
if (typeof target !== 'string' || !/^\d+\.\d+\.\d+(?:[-+][0-9A-Za-z.-]+)?$/.test(target)) {
    throw new Error(`Invalid Mol* target version: ${String(target)}`);
}
const result = {
    schemaVersion: 1,
    checkedAt: new Date().toISOString(),
    currentVersion: current,
    targetVersion: target,
    updateAvailable: current !== target,
};
const json = `${JSON.stringify(result, null, 2)}\n`;
if (output) fs.writeFileSync(output, json);
process.stdout.write(json);
