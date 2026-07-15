(() => {
    'use strict';

    let viewer = null;

    function emit(type, payload = {}) {
        const event = JSON.stringify({ type, payload, contractVersion: 1 });
        if (window.MolAndroid && typeof window.MolAndroid.postEvent === 'function') {
            window.MolAndroid.postEvent(event);
        }
        window.dispatchEvent(new CustomEvent('molapp-event', { detail: { type, payload } }));
    }

    async function dispatch(command) {
        if (!viewer) throw new Error('Viewer is not ready');
        const type = command && command.type;
        const payload = (command && command.payload) || {};

        try {
            switch (type) {
                case 'open-structure':
                    await viewer.loadStructureFromUrl(
                        String(payload.url),
                        String(payload.format || 'mmcif'),
                        Boolean(payload.binary),
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

    molstar.Viewer.create('app', {
        layoutIsExpanded: true,
        layoutShowControls: true,
        viewportShowExpand: false,
        pdbProvider: 'rcsb',
        emdbProvider: 'rcsb',
        powerPreference: 'high-performance',
    }).then(instance => {
        viewer = instance;
        window.__molstarViewer = instance;
        emit('ready', { molstarVersion: molstar.version || 'unknown' });
    }).catch(error => {
        emit('error', {
            type: 'initialize',
            message: error instanceof Error ? error.message : String(error),
        });
    });
})();
