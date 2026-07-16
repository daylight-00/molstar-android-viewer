(() => {
    'use strict';

    let viewer = null;

    function emit(type, payload = {}) {
        const detail = { type, payload, contractVersion: 1 };
        const event = JSON.stringify(detail);
        console.info(`[MolApp] ${type}`, payload);
        if (window.MolAndroid && typeof window.MolAndroid.postEvent === 'function') {
            window.MolAndroid.postEvent(event);
        }
        window.dispatchEvent(new CustomEvent('molapp-event', { detail }));
    }

    async function dispatch(command) {
        if (!viewer) throw new Error('Viewer is not ready');
        const type = command && command.type;
        const payload = (command && command.payload) || {};

        emit('command-started', { type });
        try {
            switch (type) {
                case 'open-structure':
                case 'open-file':
                    await viewer.loadStructureFromUrl(
                        String(payload.url),
                        String(payload.format || 'mmcif'),
                        Boolean(payload.binary),
                        { label: payload.name ? String(payload.name) : undefined },
                    );
                    break;
                case 'open-pdb':
                    await viewer.loadPdb(String(payload.id));
                    break;
                case 'open-alphafold':
                    await viewer.loadAlphaFoldDb(String(payload.id));
                    break;
                case 'clear':
                    await viewer.plugin.clear();
                    break;
                default:
                    throw new Error(`Unsupported command: ${String(type)}`);
            }
            emit('command-completed', { type });
        } catch (error) {
            const message = error instanceof Error ? error.message : String(error);
            emit('error', { type, message });
            throw error;
        }
    }

    window.MolApp = Object.freeze({
        contractVersion: 1,
        dispatch,
        subscribe(listener) {
            const handler = event => listener(event.detail);
            window.addEventListener('molapp-event', handler);
            return () => window.removeEventListener('molapp-event', handler);
        },
    });

    async function initialize() {
        if (!window.molstar || !window.molstar.Viewer ||
            typeof window.molstar.Viewer.create !== 'function') {
            throw new Error('The bundled Mol* Viewer API did not load');
        }

        viewer = await window.molstar.Viewer.create('app', {
            layoutIsExpanded: true,
            layoutShowControls: true,
            layoutShowLog: false,
            viewportShowExpand: false,
            pdbProvider: 'rcsb',
            emdbProvider: 'rcsb',
            powerPreference: 'high-performance',
        });
        window.__molstarViewer = viewer;
        if (window.MolBoot) window.MolBoot.markReady();
        emit('ready', {
            molstarVersion: window.molstar.version || 'unknown',
            theme: window.MolTheme ? window.MolTheme.getTheme() : 'unknown',
        });
    }

    initialize().catch(error => {
        const message = error instanceof Error ? error.message : String(error);
        if (window.MolBoot) {
            window.MolBoot.fail('boot-error', message, {
                detail: error instanceof Error ? (error.stack || error.message) : String(error),
            });
        } else {
            emit('boot-error', { message });
        }
    });
})();
