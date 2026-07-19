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
    '.github/ISSUE_TEMPLATE/config.yml',
    'docs/android.md',
    'docs/architecture.md',
    'docs/maintenance.md',
];
const retiredPaths = [
    '.github/ISSUE_TEMPLATE/feature-request.yml',
    'docs/user',
    'docs/project',
    'docs/development',
    'project.properties',
    'docs/COLLABORATION_PROTOCOL.md',
    'docs/GITHUB_COLLABORATION_WORKFLOW.md',
    'docs/local-handoff.md',
    'docs/linux-handoff.md',
    'scripts/rclone',
    'scripts/linux-bootstrap-and-publish.sh',
];
for (const item of requiredPaths) {
    if (!fs.statSync(item, { throwIfNoEntry: false })?.isFile()) {
        throw new Error(`public documentation is missing: ${item}`);
    }
}
for (const item of retiredPaths) {
    if (fs.existsSync(item)) throw new Error(`retired or private path must not be public: ${item}`);
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
    try { text = fs.readFileSync(file, 'utf8'); } catch { continue; }
    for (const marker of forbiddenText) {
        if (text.includes(marker)) throw new Error(`private operations marker found in ${file}: ${marker}`);
    }
}

for (const file of tracked.filter(file => file.endsWith('.md') && fs.existsSync(file))) {
    const text = fs.readFileSync(file, 'utf8');
    for (const match of text.matchAll(/\[[^\]]*\]\(([^)]+)\)/g)) {
        const target = match[1].split('#', 1)[0];
        if (!target || /^(?:https?:|mailto:)/.test(target)) continue;
        const resolved = path.resolve(path.dirname(file), decodeURIComponent(target));
        if (!fs.existsSync(resolved)) throw new Error(`broken relative link in ${file}: ${target}`);
    }
}

const readme = fs.readFileSync('README.md', 'utf8');
for (const marker of [
    '# Mol* Viewer for Android',
    'github.com/molstar/molstar-viewer-android/actions/workflows/ci.yml',
    'License-MIT-yellow.svg',
    'Layer 3  minimal mobile policy',
    'Layer 2  Android lifecycle, files, theme, recovery, and stable bridge',
    'Layer 1  upstream prebuilt Mol* Viewer runtime, vendored unmodified',
    'https://molstar.org/viewer-docs/',
    'git clone https://github.com/molstar/molstar-viewer-android.git',
]) {
    if (!readme.includes(marker)) throw new Error(`README contract is incomplete: ${marker}`);
}
for (const retired of [
    'independently maintained',
    'not presented as an official Mol* release',
    'subject to naming and branding guidance',
    'This project is maintained in the Mol* GitHub organization by David Hyunyoo Jang',
    'github.com/daylight-00/molstar-viewer-android',
]) {
    if (readme.includes(retired)) throw new Error(`README contains retired wording: ${retired}`);
}

const android = fs.readFileSync('docs/android.md', 'utf8');
for (const marker of [
    'https://molstar.org/viewer-docs/',
    'https://molstar.org/viewer-docs/mol_-cheat-sheet/',
    '**Open with**',
    'Android **Share**',
    "Mol*'s **Open File** control",
    'original name and MIME type',
    'app-private temporary transport area',
    'native recovery dialog',
]) {
    if (!android.includes(marker)) throw new Error(`Android documentation is incomplete: ${marker}`);
}

const architecture = fs.readFileSync('docs/architecture.md', 'utf8');
for (const marker of [
    'Layer 1: upstream Mol*',
    'Layer 2: Android integration',
    'Layer 3: minimal mobile policy',
    'viewer.loadFiles(files)',
    'layoutShowLog: false',
    'Automated upstream preparation may change only `vendor/molstar/**`',
]) {
    if (!architecture.includes(marker)) throw new Error(`architecture contract is incomplete: ${marker}`);
}

const maintenance = fs.readFileSync('docs/maintenance.md', 'utf8');
for (const marker of [
    'scripts/sync-molstar-assets.sh',
    'scripts/ci/simulate-actions.sh',
    'scripts/release/configure-github-signing.sh',
    'approved_commit',
]) {
    if (!maintenance.includes(marker)) throw new Error(`maintenance documentation is incomplete: ${marker}`);
}

const security = fs.readFileSync('SECURITY.md', 'utf8');
if (!security.includes('Report a vulnerability')) throw new Error('SECURITY.md must direct reporters to private vulnerability reporting');
if (/mailto:/i.test(security)) throw new Error('SECURITY.md must not expose an owner-specific email address');

const license = fs.readFileSync('LICENSE', 'utf8');
if (!license.includes('Copyright (c) 2026 David Hyunyoo Jang')) throw new Error('LICENSE must use the legal copyright holder');

const viewerIndex = fs.readFileSync('app/src/main/assets/viewer/index.html', 'utf8');
if (!viewerIndex.includes('<title>Mol* Viewer</title>')) throw new Error('embedded application title must remain Mol* Viewer');

const build = fs.readFileSync('app/build.gradle.kts', 'utf8');
if (!build.includes('manifestPlaceholders["appLabel"] = "Mol* Viewer"')) throw new Error('stable installed application label is missing');
if (!build.includes('manifestPlaceholders["appLabel"] = "Mol* Viewer Candidate"')) throw new Error('candidate application label is missing');

const settings = fs.readFileSync('settings.gradle.kts', 'utf8');
if (!settings.includes('rootProject.name = "molstar-viewer-android"')) throw new Error('technical project name must match the repository slug');

const promote = fs.readFileSync('.github/workflows/promote.yml', 'utf8');
if (!promote.includes('approved_commit')) throw new Error('stable promotion must retain the device-approved commit gate');
if (promote.includes('UPSTREAM_NAMING_STATUS') || promote.includes('project.properties')) throw new Error('resolved naming gate must not remain in stable promotion');

const issueConfig = fs.readFileSync('.github/ISSUE_TEMPLATE/config.yml', 'utf8');
if (!issueConfig.includes('blank_issues_enabled: true')) throw new Error('blank issues must remain available');
if (!issueConfig.includes('https://github.com/molstar/molstar-viewer-android/security/advisories/new')) throw new Error('security reporting URL must use the organization repository');

console.log('Public repository boundary passed.');
