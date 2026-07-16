package io.github.daylight00.molstarandroid

import android.annotation.SuppressLint
import android.app.Activity
import android.app.AlertDialog
import android.content.ActivityNotFoundException
import android.content.Intent
import android.content.res.Configuration
import android.graphics.Color
import android.net.Uri
import android.os.Build
import android.os.Bundle
import android.provider.OpenableColumns
import android.util.Log
import android.view.ViewGroup
import android.view.WindowInsets
import android.view.WindowInsetsController
import android.webkit.ConsoleMessage
import android.webkit.JavascriptInterface
import android.webkit.RenderProcessGoneDetail
import android.webkit.ValueCallback
import android.webkit.WebChromeClient
import android.webkit.WebResourceError
import android.webkit.WebResourceRequest
import android.webkit.WebResourceResponse
import android.webkit.WebView
import android.webkit.WebViewClient
import android.widget.FrameLayout
import android.widget.Toast
import androidx.webkit.WebViewAssetLoader
import org.json.JSONObject
import java.io.File
import java.util.UUID
import java.util.zip.GZIPInputStream

class MainActivity : Activity() {
    private lateinit var rootView: FrameLayout
    private lateinit var webView: WebView
    private lateinit var assetLoader: WebViewAssetLoader
    private lateinit var viewerFilesDir: File
    private var viewerReady = false
    private var viewerBootFailed = false
    private var lastViewerError: String? = null
    private var webFileChooserCallback: ValueCallback<Array<Uri>>? = null
    private var recoveryDialog: AlertDialog? = null
    private var lastSystemInsets = "unapplied"
    @Volatile private var currentSystemTheme = "light"
    private val pendingCommands = ArrayDeque<JSONObject>()

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        currentSystemTheme = resolveSystemTheme(resources.configuration)

        rootView = FrameLayout(this).apply {
            layoutParams = ViewGroup.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            setBackgroundColor(hostBackgroundColor(currentSystemTheme))
            clipToPadding = true
        }
        setContentView(rootView)
        updateSystemBarAppearance(currentSystemTheme)
        applySystemBarInsets(rootView)
        rootView.requestApplyInsets()

        viewerFilesDir = File(filesDir, "viewer-files").apply { mkdirs() }
        assetLoader = WebViewAssetLoader.Builder()
            .addPathHandler("/assets/", WebViewAssetLoader.AssetsPathHandler(this))
            .addPathHandler(
                "/user-files/",
                WebViewAssetLoader.InternalStoragePathHandler(this, viewerFilesDir),
            )
            .build()

        createWebView(savedInstanceState)
        handleIncomingIntent(intent)
    }

    @SuppressLint("SetJavaScriptEnabled")
    private fun createWebView(savedInstanceState: Bundle?) {
        viewerReady = false
        viewerBootFailed = false
        lastViewerError = null
        webView = WebView(this).apply {
            layoutParams = FrameLayout.LayoutParams(
                ViewGroup.LayoutParams.MATCH_PARENT,
                ViewGroup.LayoutParams.MATCH_PARENT,
            )
            setBackgroundColor(hostBackgroundColor(currentSystemTheme))
            settings.apply {
                javaScriptEnabled = true
                domStorageEnabled = true
                allowFileAccess = false
                allowContentAccess = false
                mediaPlaybackRequiresUserGesture = false
            }
            addJavascriptInterface(NativeBridge(), "MolAndroid")
            webChromeClient = object : WebChromeClient() {
                override fun onConsoleMessage(consoleMessage: ConsoleMessage): Boolean {
                    Log.d(
                        TAG,
                        "JS ${consoleMessage.messageLevel()}: ${consoleMessage.message()} " +
                            "(${consoleMessage.sourceId()}:${consoleMessage.lineNumber()})",
                    )
                    return true
                }

                override fun onShowFileChooser(
                    webView: WebView,
                    filePathCallback: ValueCallback<Array<Uri>>,
                    fileChooserParams: WebChromeClient.FileChooserParams,
                ): Boolean {
                    webFileChooserCallback?.onReceiveValue(null)
                    webFileChooserCallback = filePathCallback
                    val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
                        addCategory(Intent.CATEGORY_OPENABLE)
                        type = "*/*"
                        val acceptedMimeTypes = fileChooserParams.acceptTypes
                            .filter { it.contains('/') && !it.startsWith('.') }
                            .toTypedArray()
                        if (acceptedMimeTypes.isNotEmpty()) {
                            putExtra(Intent.EXTRA_MIME_TYPES, acceptedMimeTypes)
                        }
                        putExtra(
                            Intent.EXTRA_ALLOW_MULTIPLE,
                            fileChooserParams.mode == WebChromeClient.FileChooserParams.MODE_OPEN_MULTIPLE,
                        )
                    }
                    return try {
                        startActivityForResult(intent, REQUEST_WEB_FILE_CHOOSER)
                        true
                    } catch (error: ActivityNotFoundException) {
                        Log.e(TAG, "No Android file picker is available", error)
                        webFileChooserCallback = null
                        filePathCallback.onReceiveValue(null)
                        toast("No file picker is available")
                        true
                    }
                }
            }
            webViewClient = object : WebViewClient() {
                override fun shouldInterceptRequest(
                    view: WebView,
                    request: WebResourceRequest,
                ): WebResourceResponse? = assetLoader.shouldInterceptRequest(request.url)

                override fun shouldOverrideUrlLoading(
                    view: WebView,
                    request: WebResourceRequest,
                ): Boolean {
                    val uri = request.url
                    if (uri.host == "appassets.androidplatform.net") return false
                    startActivity(Intent(Intent.ACTION_VIEW, uri))
                    return true
                }

                override fun onPageFinished(view: WebView, url: String) {
                    Log.d(TAG, "Viewer page loaded: $url")
                }

                override fun onReceivedError(
                    view: WebView,
                    request: WebResourceRequest,
                    error: WebResourceError,
                ) {
                    if (request.isForMainFrame) {
                        reportHostFailure("WebView load failed: ${error.description}")
                    }
                }

                override fun onReceivedHttpError(
                    view: WebView,
                    request: WebResourceRequest,
                    errorResponse: WebResourceResponse,
                ) {
                    if (request.isForMainFrame) {
                        reportHostFailure("Viewer HTTP error: ${errorResponse.statusCode}")
                    }
                }

                override fun onRenderProcessGone(
                    view: WebView,
                    detail: RenderProcessGoneDetail,
                ): Boolean {
                    val message = "WebView renderer exited and was restarted"
                    Log.e(TAG, "$message; didCrash=${detail.didCrash()}")
                    (view.parent as? ViewGroup)?.removeView(view)
                    view.destroy()
                    createWebView(null)
                    viewerBootFailed = true
                    lastViewerError = message
                    showRecoveryDialog(message)
                    return true
                }
            }
        }

        rootView.addView(webView)
        if (savedInstanceState == null || webView.restoreState(savedInstanceState) == null) {
            webView.loadUrl(ViewerContract.ENTRYPOINT)
        }
    }

    private fun applySystemBarInsets(container: FrameLayout) {
        container.setOnApplyWindowInsetsListener { target, insets ->
            if (Build.VERSION.SDK_INT >= 30) {
                val bars = insets.getInsets(
                    WindowInsets.Type.systemBars() or WindowInsets.Type.displayCutout(),
                )
                target.setPadding(bars.left, bars.top, bars.right, bars.bottom)
                lastSystemInsets = "${bars.left},${bars.top},${bars.right},${bars.bottom}"
                Log.d(TAG, "Applied host insets: $lastSystemInsets")
                WindowInsets.CONSUMED
            } else {
                @Suppress("DEPRECATION")
                val left = insets.systemWindowInsetLeft
                val top = insets.systemWindowInsetTop
                val right = insets.systemWindowInsetRight
                val bottom = insets.systemWindowInsetBottom
                target.setPadding(left, top, right, bottom)
                lastSystemInsets = "$left,$top,$right,$bottom"
                Log.d(TAG, "Applied legacy host insets: $lastSystemInsets")
                @Suppress("DEPRECATION")
                insets.consumeSystemWindowInsets()
            }
        }
    }

    @Deprecated("Retained for a dependency-light bootstrap project")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode == REQUEST_WEB_FILE_CHOOSER) {
            val callback = webFileChooserCallback
            webFileChooserCallback = null
            callback?.onReceiveValue(
                WebChromeClient.FileChooserParams.parseResult(resultCode, data),
            )
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        setIntent(intent)
        handleIncomingIntent(intent)
    }

    private fun handleIncomingIntent(intent: Intent?) {
        val uri = when (intent?.action) {
            Intent.ACTION_VIEW -> intent.data
            Intent.ACTION_SEND -> if (Build.VERSION.SDK_INT >= 33) {
                intent.getParcelableExtra(Intent.EXTRA_STREAM, Uri::class.java)
            } else {
                @Suppress("DEPRECATION")
                intent.getParcelableExtra(Intent.EXTRA_STREAM)
            }
            else -> null
        }
        uri?.let(::importAndOpen)
    }

    private fun importAndOpen(uri: Uri) {
        Thread {
            runCatching {
                val sourceName = queryDisplayName(uri) ?: uri.lastPathSegment ?: "structure.cif"
                val safeName = sanitizeFileName(sourceName)
                val detected = detectStructureFile(safeName)
                val storedName = if (detected.gzip) safeName.dropLast(3) else safeName
                val target = File(viewerFilesDir, "${UUID.randomUUID()}-$storedName")
                contentResolver.openInputStream(uri).use { rawInput ->
                    requireNotNull(rawInput) { "Cannot open $uri" }
                    val decodedInput = if (detected.gzip) GZIPInputStream(rawInput) else rawInput
                    decodedInput.use { input -> target.outputStream().use(input::copyTo) }
                }
                val url = "${ViewerContract.ORIGIN}/user-files/${target.name}"
                ViewerContract.openFile(url, storedName, detected.format, detected.binary)
            }.onSuccess { command ->
                runOnUiThread {
                    val queued = !viewerReady
                    dispatch(command)
                    toast(if (queued) "Structure queued while viewer starts" else "Opening structure")
                }
            }.onFailure { error ->
                Log.e(TAG, "Failed to import structure", error)
                runOnUiThread { toast(error.message ?: "Failed to open structure") }
            }
        }.start()
    }

    private fun queryDisplayName(uri: Uri): String? {
        if (uri.scheme != "content") return null
        return contentResolver.query(uri, arrayOf(OpenableColumns.DISPLAY_NAME), null, null, null)
            ?.use { cursor ->
                if (!cursor.moveToFirst()) null else cursor.getString(0)
            }
    }

    private data class DetectedStructureFile(
        val format: String,
        val binary: Boolean,
        val gzip: Boolean,
    )

    private fun sanitizeFileName(name: String): String {
        val sanitized = name.substringAfterLast('/').replace(Regex("[^A-Za-z0-9._-]"), "_")
        return sanitized.ifBlank { "structure.cif" }
    }

    private fun detectStructureFile(name: String): DetectedStructureFile {
        val lowerName = name.lowercase()
        val gzip = lowerName.endsWith(".gz")
        val uncompressedName = if (gzip) lowerName.dropLast(3) else lowerName
        val extension = uncompressedName.substringAfterLast('.', "")
        val (format, binary) = when (extension) {
            "pdb", "ent" -> "pdb" to false
            "pdbqt" -> "pdbqt" to false
            "pqr" -> "pqr" to false
            "cif", "mmcif", "mcif" -> "mmcif" to false
            "bcif" -> "mmcif" to true
            "gro" -> "gro" to false
            "xyz" -> "xyz" to false
            "data" -> "lammps_data" to false
            "lammpstrj" -> "lammps_traj_data" to false
            "mol" -> "mol" to false
            "sdf", "sd" -> "sdf" to false
            "mol2" -> "mol2" to false
            else -> throw IllegalArgumentException(
                "Unsupported structure extension: ${if (extension.isBlank()) name else ".$extension"}",
            )
        }
        return DetectedStructureFile(format, binary, gzip)
    }

    private fun dispatch(command: JSONObject) {
        if (!viewerReady) {
            pendingCommands.addLast(command)
            return
        }
        val quoted = JSONObject.quote(command.toString())
        webView.evaluateJavascript("window.MolApp.dispatch(JSON.parse($quoted));", null)
    }

    private fun flushPendingCommands() {
        while (viewerReady && pendingCommands.isNotEmpty()) {
            dispatch(pendingCommands.removeFirst())
        }
    }

    private fun reloadViewer() {
        recoveryDialog?.dismiss()
        recoveryDialog = null
        viewerReady = false
        viewerBootFailed = false
        lastViewerError = null
        webView.reload()
        toast("Reloading viewer")
    }

    private fun reportHostFailure(message: String) {
        viewerBootFailed = true
        lastViewerError = message
        Log.e(TAG, message)
        showRecoveryDialog(message)
    }

    private fun showRecoveryDialog(message: String) {
        if (isFinishing || (Build.VERSION.SDK_INT >= 17 && isDestroyed)) return
        recoveryDialog?.dismiss()
        recoveryDialog = AlertDialog.Builder(this)
            .setTitle("Viewer unavailable")
            .setMessage(message)
            .setPositiveButton("Reload") { _, _ -> reloadViewer() }
            .setNeutralButton("Diagnostics") { _, _ -> showDiagnostics() }
            .setNegativeButton("Close", null)
            .show()
    }

    private fun showDiagnostics() {
        val webViewVersion = if (Build.VERSION.SDK_INT >= 26) {
            WebView.getCurrentWebViewPackage()?.versionName ?: "unknown"
        } else {
            "unavailable below Android 8"
        }
        val message = buildString {
            appendLine("ready=$viewerReady")
            appendLine("bootFailed=$viewerBootFailed")
            appendLine("pendingCommands=${pendingCommands.size}")
            appendLine("url=${webView.url ?: "none"}")
            appendLine("webView=$webViewVersion")
            appendLine("insets=$lastSystemInsets")
            appendLine("theme=$currentSystemTheme")
            append("lastError=${lastViewerError ?: "none"}")
        }
        AlertDialog.Builder(this)
            .setTitle("Viewer diagnostics")
            .setMessage(message)
            .setPositiveButton("OK", null)
            .show()
    }

    override fun onConfigurationChanged(newConfig: Configuration) {
        super.onConfigurationChanged(newConfig)
        applySystemTheme(newConfig)
    }

    private fun applySystemTheme(configuration: Configuration) {
        currentSystemTheme = resolveSystemTheme(configuration)
        val background = hostBackgroundColor(currentSystemTheme)
        if (::rootView.isInitialized) rootView.setBackgroundColor(background)
        if (::webView.isInitialized) {
            webView.setBackgroundColor(background)
            val quotedTheme = JSONObject.quote(currentSystemTheme)
            webView.evaluateJavascript(
                "window.MolTheme && window.MolTheme.setTheme($quotedTheme);",
                null,
            )
        }
        updateSystemBarAppearance(currentSystemTheme)
    }

    private fun resolveSystemTheme(configuration: Configuration): String =
        if (configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK == Configuration.UI_MODE_NIGHT_YES) {
            "dark"
        } else {
            "light"
        }

    private fun hostBackgroundColor(theme: String): Int =
        if (theme == "dark") Color.rgb(16, 20, 24) else Color.rgb(247, 247, 248)

    private fun updateSystemBarAppearance(theme: String) {
        val lightBars = theme == "light"
        if (Build.VERSION.SDK_INT >= 30) {
            val mask = WindowInsetsController.APPEARANCE_LIGHT_STATUS_BARS or
                WindowInsetsController.APPEARANCE_LIGHT_NAVIGATION_BARS
            window.insetsController?.setSystemBarsAppearance(if (lightBars) mask else 0, mask)
        } else {
            @Suppress("DEPRECATION")
            var flags = window.decorView.systemUiVisibility
            if (Build.VERSION.SDK_INT >= 23) {
                @Suppress("DEPRECATION")
                flags = if (lightBars) {
                    flags or android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR
                } else {
                    flags and android.view.View.SYSTEM_UI_FLAG_LIGHT_STATUS_BAR.inv()
                }
            }
            if (Build.VERSION.SDK_INT >= 26) {
                @Suppress("DEPRECATION")
                flags = if (lightBars) {
                    flags or android.view.View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR
                } else {
                    flags and android.view.View.SYSTEM_UI_FLAG_LIGHT_NAVIGATION_BAR.inv()
                }
            }
            @Suppress("DEPRECATION")
            window.decorView.systemUiVisibility = flags
        }
    }

    override fun onSaveInstanceState(outState: Bundle) {
        webView.saveState(outState)
        super.onSaveInstanceState(outState)
    }

    override fun onDestroy() {
        webFileChooserCallback?.onReceiveValue(null)
        webFileChooserCallback = null
        recoveryDialog?.dismiss()
        recoveryDialog = null
        webView.removeJavascriptInterface("MolAndroid")
        webView.destroy()
        super.onDestroy()
    }

    @Deprecated("Uses WebView history only for local application navigation")
    override fun onBackPressed() {
        if (webView.canGoBack()) webView.goBack() else super.onBackPressed()
    }

    private fun toast(message: String) =
        Toast.makeText(this, message, Toast.LENGTH_SHORT).show()

    inner class NativeBridge {
        @JavascriptInterface
        fun getSystemTheme(): String = currentSystemTheme

        @JavascriptInterface
        fun postEvent(json: String) {
            runOnUiThread {
                runCatching { JSONObject(json) }
                    .onSuccess { event ->
                        val type = event.optString("type")
                        val payload = event.optJSONObject("payload")
                        when (type) {
                            "ready" -> {
                                viewerReady = true
                                viewerBootFailed = false
                                lastViewerError = null
                                recoveryDialog?.dismiss()
                                recoveryDialog = null
                                flushPendingCommands()
                            }
                            "command-completed" -> {
                                val commandType = payload?.optString("type")
                                if (commandType == "open-structure" || commandType == "open-file") {
                                    toast("Structure loaded")
                                }
                            }
                            "boot-error", "boot-timeout" -> {
                                val message = payload?.optString("message") ?: "Viewer startup failed"
                                viewerBootFailed = true
                                lastViewerError = message
                                showRecoveryDialog(message)
                            }
                            "error" -> {
                                val message = payload?.optString("message") ?: "Viewer error"
                                lastViewerError = message
                                toast(message)
                            }
                        }
                        Log.d(TAG, "Viewer event: $event")
                    }
                    .onFailure { Log.e(TAG, "Invalid viewer event: $json", it) }
            }
        }
    }

    companion object {
        private const val TAG = "MolstarAndroid"
        private const val REQUEST_WEB_FILE_CHOOSER = 1002
    }
}
