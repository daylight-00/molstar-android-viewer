package io.github.daylight00.molstarandroid

import org.json.JSONObject

/** Stable host-facing contract. Mol* implementation details stay behind app-bridge.js. */
object ViewerContract {
    const val ORIGIN = "https://appassets.androidplatform.net"
    const val ENTRYPOINT = "$ORIGIN/assets/viewer/index.html"

    fun openStructure(url: String, format: String, binary: Boolean): JSONObject =
        command(
            "open-structure",
            JSONObject()
                .put("url", url)
                .put("format", format)
                .put("binary", binary),
        )

    fun openFile(url: String, name: String, format: String, binary: Boolean): JSONObject =
        command(
            "open-file",
            JSONObject()
                .put("url", url)
                .put("name", name)
                .put("format", format)
                .put("binary", binary),
        )

    fun openPdb(id: String): JSONObject =
        command("open-pdb", JSONObject().put("id", id.trim().uppercase()))

    fun clear(): JSONObject = command("clear", JSONObject())

    private fun command(type: String, payload: JSONObject): JSONObject =
        JSONObject()
            .put("type", type)
            .put("payload", payload)
}
