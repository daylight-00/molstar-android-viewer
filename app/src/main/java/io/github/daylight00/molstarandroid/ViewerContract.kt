package io.github.daylight00.molstarandroid

import org.json.JSONArray
import org.json.JSONObject

/** Stable platform-facing contract. Mol* implementation details stay behind app-bridge.js. */
object ViewerContract {
    const val ORIGIN = "https://appassets.androidplatform.net"
    const val ENTRYPOINT = "$ORIGIN/assets/viewer/index.html"

    /**
     * Transport native files without interpreting their molecular format on Android.
     * File names and MIME types are preserved so Mol* can use its own registry.
     */
    fun openFiles(batchId: String, files: JSONArray): JSONObject =
        command(
            "open-files",
            JSONObject()
                .put("batchId", batchId)
                .put("files", files),
        )

    /** Explicit URL loading remains available for future native/custom controls. */
    fun openStructure(url: String, format: String, binary: Boolean): JSONObject =
        command(
            "open-structure",
            JSONObject()
                .put("url", url)
                .put("format", format)
                .put("binary", binary),
        )

    fun openPdb(id: String): JSONObject =
        command("open-pdb", JSONObject().put("id", id.trim().uppercase()))

    fun openAlphaFold(id: String): JSONObject =
        command("open-alphafold", JSONObject().put("id", id.trim().uppercase()))

    fun clear(): JSONObject = command("clear", JSONObject())

    private fun command(type: String, payload: JSONObject): JSONObject =
        JSONObject()
            .put("type", type)
            .put("payload", payload)
}
