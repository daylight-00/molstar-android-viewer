#!/usr/bin/env node
import { execFileSync } from 'node:child_process';
import fs from 'node:fs';
import path from 'node:path';

const requiredPaths = [
    'README.md',
    'CONTRIBUTING.md',
    'SECURITY.md',
    '.github/PULL_REQUEST_TEMPLATE.md',
    '.github/ISSUE_TEMPLATE/bug-report.yml',
    '.github/ISSUE_TEMPLATE/feature-request.yml',
    '.github/ISSUE_TEMPLATE/config.yml',
    'docs/user/README.md',
    'docs/user/troubleshooting.md',
    'docs/development/README.md',
    'docs/development/architecture.md',
    'docs/development/upstream-molstar.md',
    'docs/development/automation.md',
    'docs/development/releasing.md',
];

const forbiddenPaths = [
    'docs/COLLABORATION_PROTOCOL.md',
    'docs/GITHUB_COLLABORATION_WORKFLOW.md',
    'docs/local-handoff.md',
    'docs/linux-handoff.md',
    'scripts/rclone',
    'scripts/linux-bootstrap-and-publish.sh',
];

for (const item of requiredPaths) {
    if (!fs.statSync(item, { throwIfNoEntry: false })?.isFile()) {
        throw new Error(`public/developer documentation is missing: ${item}`);
    }
}
for (const item of forbiddenPaths) {
    if (fs.existsSync(item)) throw new Error(`private operations path must not be public: ${item}`);
}

const tracked = execFileSync('git', ['ls-files', '-z'], { encoding: 'utf8' })
    .split('\0')
    .filter(Boolean);
const forbiddenText = [
    'HW-T/',
    'agent-to-user',
    'user-to-agent',
    'single-runner',
    'hwjang00@snu.ac.kr',
    '$HOME/projects/molstar-android-viewer-bootstrap',
    'Assistant changes are delivered',
    'Google Drive carries bounded runner',
];
const self = 'scripts/verify-public-boundary.mjs';
const binaryExtensions = new Set(['.jar', '.ico', '.jpg', '.png', '.apk', '.zst', '.bundle']);
for (const file of tracked) {
    if (file === self || file.startsWith('app/src/main/assets/viewer/vendor/molstar/')) continue;
    if (binaryExtensions.has(path.extname(file).toLowerCase())) continue;
    let text;
    try {
        text = fs.readFileSync(file, 'utf8');
    } catch {
        continue;
    }
    for (const marker of forbiddenText) {
        if (text.includes(marker)) throw new Error(`private operations marker found in ${file}: ${marker}`);
    }
}

const markdown = tracked.filter(file => file.endsWith('.md') && fs.existsSync(file));
for (const file of markdown) {
    const text = fs.readFileSync(file, 'utf8');
    for (const match of text.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)) {
        const target = match[1].split('#', 1)[0];
        if (!target || /^(?:https?:|mailto:)/.test(target)) continue;
        const resolved = path.resolve(path.dirname(file), decodeURIComponent(target));
        if (!fs.existsSync(resolved)) throw new Error(`broken relative link in ${file}: ${target}`);
    }
}

const security = fs.readFileSync('SECURITY.md', 'utf8');
if (!security.includes('Report a vulnerability')) throw new Error('SECURITY.md must direct reporters to private vulnerability reporting');
if (/mailto:/i.test(security)) throw new Error('SECURITY.md must not expose an owner-specific email address');

const issueConfig = fs.readFileSync('.github/ISSUE_TEMPLATE/config.yml', 'utf8');
if (!issueConfig.includes('/security/advisories/new')) throw new Error('issue config must link to private vulnerability reporting');
if (!issueConfig.includes('github.com/molstar/molstar/issues')) throw new Error('issue config must identify the upstream Mol* tracker');

console.log('Public/developer/private repository boundary passed.');
