(() => {
    'use strict';

    const lightSheet = document.getElementById('molstar-theme-light');
    const darkSheet = document.getElementById('molstar-theme-dark');
    let currentTheme = 'light';

    function normalizeTheme(value) {
        return String(value).toLowerCase() === 'dark' ? 'dark' : 'light';
    }

    function readNativeTheme() {
        try {
            if (window.MolAndroid && typeof window.MolAndroid.getSystemTheme === 'function') {
                return normalizeTheme(window.MolAndroid.getSystemTheme());
            }
        } catch (error) {
            console.warn('[MolTheme] Could not read Android theme', error);
        }
        return window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches
            ? 'dark'
            : 'light';
    }

    function setTheme(value) {
        const theme = normalizeTheme(value);
        currentTheme = theme;
        document.documentElement.dataset.theme = theme;
        document.documentElement.style.colorScheme = theme;
        if (lightSheet) lightSheet.disabled = theme !== 'light';
        if (darkSheet) darkSheet.disabled = theme !== 'dark';
        window.dispatchEvent(new CustomEvent('mol-theme-changed', { detail: { theme } }));
        return theme;
    }

    window.MolTheme = Object.freeze({
        setTheme,
        getTheme() {
            return currentTheme;
        },
    });

    setTheme(readNativeTheme());
})();
