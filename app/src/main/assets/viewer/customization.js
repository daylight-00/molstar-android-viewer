(() => {
    'use strict';

    // Layer 3: explicit, minimal Android/mobile adaptation only.
    // Keep this separate from both the upstream Mol* bundle and the platform bridge.
    const viewerOptions = Object.freeze({
        layoutShowLog: false,
        viewportShowExpand: false,
    });

    function mount(context) {
        const root = context && context.root;
        if (!root) throw new Error('The custom UI root is missing');
        root.replaceChildren();
        // Intentionally empty. Future custom UI mounts here without modifying Mol* DOM.
    }

    window.MolCustomization = Object.freeze({
        contractVersion: 1,
        viewerOptions,
        mount,
    });
})();
