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
    'docs/project/README.md',
    'docs/project/naming-and-branding.md',
    'docs/development/README.md',
    'docs/development/architecture.md',
    'docs/development/upstream-molstar.md',
    'docs/development/automation.md',
    'docs/development/releasing.md',
    'project.properties',
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
    try { text = fs.readFileSync(file, 'utf8'); } catch { continue; }
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

const license = fs.readFileSync('LICENSE', 'utf8');
if (!license.includes('Copyright (c) 2026 David Hyunyoo Jang')) throw new Error('LICENSE must use the owner legal name');
if (license.includes('Copyright (c) 2026 daylight-00')) throw new Error('LICENSE must not use the GitHub handle as the copyright holder');

const readme = fs.readFileSync('README.md', 'utf8');
if (!readme.startsWith('# Mol* Viewer for Android\n')) throw new Error('public project title must be Mol* Viewer for Android');
if (!readme.includes('naming and branding guidance from the Mol* maintainers')) throw new Error('README must preserve the pending upstream guidance boundary');
if (!readme.includes('github.com/daylight-00/molstar-viewer-android/actions/workflows/ci.yml')) throw new Error('CI badge must use the renamed repository URL');
if (!readme.includes('git clone https://github.com/daylight-00/molstar-viewer-android.git')) throw new Error('clone instructions must use the renamed repository URL');
if (readme.includes('github.com/daylight-00/molstar-android-viewer')) throw new Error('README contains the retired repository URL');

const userGuide = fs.readFileSync('docs/user/README.md', 'utf8');
if (!userGuide.includes('Mol* Viewer for Android packages the official Mol* Viewer runtime')) throw new Error('user guide must use the public project title');
if (!userGuide.includes('Mol* maintainer naming and branding guidance')) throw new Error('user guide must preserve the stable-release naming gate');

const naming = fs.readFileSync('docs/project/naming-and-branding.md', 'utf8');
for (const marker of [
    'UPSTREAM_NAMING_STATUS=pending',
    'May the Android application use the display name **Mol* Viewer**?',
    'May the project use the title **Mol* Viewer for Android**?',
    'May the Mol* logo be used for the application icon',
    'https://github.com/daylight-00/molstar-viewer-android',
    'Stable-release gate',
]) {
    if (!naming.includes(marker)) throw new Error(`naming guidance record is incomplete: ${marker}`);
}
const projectProperties = fs.readFileSync('project.properties', 'utf8');
if (!/^UPSTREAM_NAMING_STATUS=pending$/m.test(projectProperties)) throw new Error('upstream naming status must remain pending before maintainer guidance is recorded');

const viewerIndex = fs.readFileSync('app/src/main/assets/viewer/index.html', 'utf8');
if (!viewerIndex.includes('<title>Mol* Viewer</title>')) throw new Error('embedded application title must remain Mol* Viewer');
const legacyViewerTitle = '<title>Mol* ' + 'Android Viewer</title>';
if (viewerIndex.includes(legacyViewerTitle)) throw new Error('legacy embedded application title must be removed');

const build = fs.readFileSync('app/build.gradle.kts', 'utf8');
if (!build.includes('manifestPlaceholders["appLabel"] = "Mol* Viewer"')) throw new Error('stable installed application label must remain Mol* Viewer');
if (!build.includes('manifestPlaceholders["appLabel"] = "Mol* Viewer Candidate"')) throw new Error('candidate application label must remain distinguishable');

const settings = fs.readFileSync('settings.gradle.kts', 'utf8');
if (!settings.includes('rootProject.name = "molstar-viewer-android"')) throw new Error('technical project name must match the renamed repository slug');
const contributing = fs.readFileSync('CONTRIBUTING.md', 'utf8');
if (!contributing.includes('cd molstar-viewer-android')) throw new Error('contributor checkout path must match the renamed repository slug');

const releaseScript = fs.readFileSync('scripts/release/prepare-release.sh', 'utf8');
if (!releaseScript.includes('title: `Mol* Viewer for Android ${artifact.versionName}`')) throw new Error('stable release title must use the public project title');
const promote = fs.readFileSync('.github/workflows/promote.yml', 'utf8');
if (!promote.includes('Verify upstream naming and branding status')) throw new Error('stable promotion must verify upstream naming status');
if (!promote.includes('UPSTREAM_NAMING_STATUS')) throw new Error('stable promotion naming gate is missing');

const issueConfig = fs.readFileSync('.github/ISSUE_TEMPLATE/config.yml', 'utf8');
if (!issueConfig.includes('https://github.com/daylight-00/molstar-viewer-android/security/advisories/new')) throw new Error('issue config must use the renamed private-report URL');
if (!issueConfig.includes('github.com/molstar/molstar/issues')) throw new Error('issue config must identify the upstream Mol* tracker');
if (issueConfig.includes('github.com/daylight-00/molstar-android-viewer')) throw new Error('issue config contains the retired repository URL');

console.log('Public/developer/private repository boundary passed.');
