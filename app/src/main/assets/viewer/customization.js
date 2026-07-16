(() => {
    'use strict';

    // Layer 3: explicit, minimal Android/mobile adaptation only.
    // Keep this separate from both the upstream Mol* bundle and the platform bridge.
    // The sole active product policy is hiding Mol*'s non-live log panel.
    const viewerOptions = Object.freeze({
        layoutShowLog: false,
    });

    function mount(context) {
        const root = context && context.root;
        if (!root) throw new Error('The custom UI root is missing');
        root.replaceChildren();
        // Intentionally empty. Future custom UI mounts here without modifying Mol* DOM.
    }

    window.MolCustomization = Object.freeze({
        contractVersion: 2,
        viewerOptions,
        mount,
    });
})();
