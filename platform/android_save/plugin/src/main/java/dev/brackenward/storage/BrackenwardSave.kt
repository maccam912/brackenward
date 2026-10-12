package dev.brackenward.storage

import android.app.Activity
import android.content.Intent
import android.net.Uri
import org.godotengine.godot.Godot
import org.godotengine.godot.plugin.GodotPlugin
import org.godotengine.godot.plugin.SignalInfo
import org.godotengine.godot.plugin.UsedByGodot
import java.util.concurrent.Executors

class BrackenwardSave(godot: Godot) : GodotPlugin(godot) {
    private val io = Executors.newSingleThreadExecutor()
    private var activeRequest = 0
    private var selectedUri: Uri? = null
    private var exporting = false
    private var working = false
    private var destroyed = false

    override fun getPluginName() = "BrackenwardSave"
    override fun getPluginSignals() = setOf(
        SignalInfo("document_result", Int::class.javaObjectType, String::class.java, ByteArray::class.java)
    )

    @UsedByGodot
    fun getDensity(): Double = activity?.resources?.displayMetrics?.density?.toDouble() ?: 1.0

    @UsedByGodot
    fun chooseExportDestination(requestId: Int, suggestedName: String) {
        choose(requestId, true, suggestedName)
    }

    @UsedByGodot
    fun chooseImportDocument(requestId: Int) {
        choose(requestId, false, "")
    }

    @Synchronized
    private fun choose(requestId: Int, export: Boolean, name: String) {
        if (requestId <= 0 || destroyed) { signal(requestId, "invalid_request"); return }
        if (activeRequest != 0) { signal(requestId, "busy"); return }
        val host = activity ?: run { signal(requestId, "no_activity"); return }
        activeRequest = requestId
        selectedUri = null
        exporting = export
        working = false
        host.runOnUiThread {
            try {
                val intent = Intent(if (export) Intent.ACTION_CREATE_DOCUMENT else Intent.ACTION_OPEN_DOCUMENT)
                    .addCategory(Intent.CATEGORY_OPENABLE)
                    .setType("application/octet-stream")
                if (export) intent.putExtra(Intent.EXTRA_TITLE, name.take(96).replace('/', '_'))
                // Provider grants are temporary, sufficient for this one immediate operation.
                host.startActivityForResult(intent, if (export) EXPORT_CODE else IMPORT_CODE)
            } catch (_: Exception) { finish(requestId, "picker_failed") }
        }
    }

    @Synchronized
    override fun onMainActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        if (requestCode != EXPORT_CODE && requestCode != IMPORT_CODE) return
        if (activeRequest == 0 || destroyed || (requestCode == EXPORT_CODE) != exporting) return
        val id = activeRequest
        if (resultCode != Activity.RESULT_OK) { finish(id, "canceled"); return }
        val uri = data?.data
        if (uri == null || uri.scheme != "content") { finish(id, "invalid_document"); return }
        selectedUri = uri
        signal(id, if (exporting) "export_selected" else "import_selected")
    }

    @UsedByGodot
    @Synchronized
    fun writeSelectedDocument(requestId: Int, bytes: ByteArray) {
        val uri = selectedUri
        if (requestId != activeRequest || uri == null || !exporting || working) {
            signal(requestId, "stale_request"); return
        }
        if (bytes.isEmpty() || bytes.size > BoundedDocuments.MAX_BYTES) { finish(requestId, "too_large"); return }
        val resolver = activity?.contentResolver ?: run { finish(requestId, "no_activity"); return }
        val snapshot = bytes.copyOf()
        working = true
        io.execute {
            try {
                (resolver.openOutputStream(uri, "wt") ?: error("no_stream")).use {
                    it.write(snapshot)
                    it.flush()
                }
                val verified = (resolver.openInputStream(uri) ?: error("no_stream")).use {
                    BoundedDocuments.read(it, snapshot.size)
                }
                if (!verified.contentEquals(snapshot)) error("verify_failed")
                finish(requestId, "written")
            } catch (_: Exception) { finish(requestId, "write_failed") }
        }
    }

    @UsedByGodot
    @Synchronized
    fun readSelectedDocument(requestId: Int, limit: Int) {
        val uri = selectedUri
        if (requestId != activeRequest || uri == null || exporting || working) {
            signal(requestId, "stale_request"); return
        }
        if (limit !in 1..BoundedDocuments.MAX_BYTES) { finish(requestId, "invalid_limit"); return }
        val resolver = activity?.contentResolver ?: run { finish(requestId, "no_activity"); return }
        working = true
        io.execute {
            try {
                val bytes = (resolver.openInputStream(uri) ?: error("no_stream")).use {
                    BoundedDocuments.read(it, limit)
                }
                finish(requestId, "read", bytes)
            } catch (error: IllegalArgumentException) {
                finish(requestId, if (error.message == "too_large") "too_large" else "read_failed")
            } catch (_: Exception) { finish(requestId, "read_failed") }
        }
    }

    @Synchronized
    private fun finish(id: Int, result: String, bytes: ByteArray = byteArrayOf()) {
        if (id != activeRequest || destroyed) return
        activeRequest = 0
        selectedUri = null
        working = false
        signal(id, result, bytes)
    }

    private fun signal(id: Int, result: String, bytes: ByteArray = byteArrayOf()) {
        runOnRenderThread { if (!destroyed) emitSignal("document_result", id, result, bytes) }
    }

    @Synchronized
    override fun onMainDestroy() {
        destroyed = true
        activeRequest = 0
        selectedUri = null
        io.shutdown()
    }

    companion object {
        private const val EXPORT_CODE = 43821
        private const val IMPORT_CODE = 43822
    }
}
