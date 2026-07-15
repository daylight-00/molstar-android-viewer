(() => {
    'use strict';

    const statusNode = document.getElementById('boot-status');
    let ready = false;
    let terminalFailure = false;

    function stringifyReason(reason) {
        if (reason instanceof Error) return reason.stack || reason.message;
        if (typeof reason === 'string') return reason;
        try {
            return JSON.stringify(reason);
        } catch (_) {
            return String(reason);
        }
    }

    function post(type, payload) {
        const event = { type, payload, contractVersion: 1 };
        const encoded = JSON.stringify(event);
        console.error(`[MolBoot] ${type}: ${payload.message || ''}`, payload);
        if (window.MolAndroid && typeof window.MolAndroid.postEvent === 'function') {
            window.MolAndroid.postEvent(encoded);
        }
        window.dispatchEvent(new CustomEvent('molapp-event', { detail: event }));
    }

    function setStatus(message, state) {
        if (!statusNode) return;
        statusNode.textContent = message;
        statusNode.dataset.state = state;
        statusNode.hidden = false;
    }

    function fail(type, message, details = {}) {
        if (ready || terminalFailure) return;
        terminalFailure = true;
        const payload = { message, ...details };
        setStatus(message, 'error');
        post(type, payload);
    }

    window.MolBoot = Object.freeze({
        markReady() {
            ready = true;
            terminalFailure = false;
            if (statusNode) statusNode.hidden = true;
        },
        fail,
    });

    window.addEventListener('error', event => {
        fail('boot-error', event.message || 'Mol* JavaScript initialization failed', {
            source: event.filename || '',
            line: event.lineno || 0,
            column: event.colno || 0,
            detail: stringifyReason(event.error),
        });
    });

    window.addEventListener('unhandledrejection', event => {
        fail('boot-error', 'Mol* initialization promise was rejected', {
            detail: stringifyReason(event.reason),
        });
    });

    window.setTimeout(() => {
        if (!ready) {
            fail('boot-timeout', 'Mol* did not become ready within 20 seconds');
        }
    }, 20000);
})();
