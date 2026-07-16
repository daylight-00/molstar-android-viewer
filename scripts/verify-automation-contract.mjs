#!/usr/bin/env node
import fs from 'node:fs';

const read = path => fs.readFileSync(path, 'utf8');
const build = read('app/build.gradle.kts');
const manifest = read('app/src/main/AndroidManifest.xml');
const verify = read('scripts/verify.sh');
const release = read('scripts/release/prepare-release.sh');
const update = read('scripts/automation/prepare-molstar-update.sh');
const scope = read('scripts/automation/verify-update-scope.sh');

function requireMatch(condition, message) {
    if (!condition) throw new Error(message);
}
requireMatch(build.includes('create("stable")'), 'stable product flavor is missing');
requireMatch(build.includes('create("candidate")'), 'candidate product flavor is missing');
requireMatch(build.includes('applicationIdSuffix = ".candidate"'), 'candidate application ID isolation is missing');
requireMatch(build.includes('MOLSTAR_ANDROID_KEYSTORE_FILE'), 'environment-driven signing contract is missing');
requireMatch(build.includes('MOLSTAR_ANDROID_VERSION_CODE'), 'environment-driven version code is missing');
requireMatch(manifest.includes('android:label="${appLabel}"'), 'variant application label placeholder is missing');
requireMatch(verify.includes('VERIFY_VARIANT'), 'verification must target an explicit Android variant');
requireMatch(release.includes('RELEASE_READY=1'), 'release preparation status contract is missing');
requireMatch(update.includes('verify-update-scope.sh'), 'automated Mol* update scope gate is missing');
requireMatch(scope.includes('app/src/main/assets/viewer/vendor/molstar/*'), 'update scope is not restricted to Layer 1');
requireMatch(fs.existsSync('scripts/ci/simulate-actions.sh'), 'local Actions simulation is missing');
requireMatch(fs.existsSync('docs/automation-readiness.md'), 'automation readiness documentation is missing');
console.log('Automation and release-readiness contract passed.');
