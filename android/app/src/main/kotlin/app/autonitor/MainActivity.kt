package app.autonitor

import android.app.Activity
import android.content.Intent
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.File
import java.io.FileInputStream

class MainActivity : FlutterActivity() {
    companion object {
        private const val BACKUP_CHANNEL = "app.autonitor/backup_file"
        private const val CREATE_DOCUMENT_REQUEST = 48121
    }

    private var pendingSave: PendingSave? = null
    private val mainHandler = Handler(Looper.getMainLooper())

    private data class PendingSave(
        val sourcePath: String,
        val result: MethodChannel.Result,
    )

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, BACKUP_CHANNEL)
            .setMethodCallHandler { call, result -> handleBackupCall(call, result) }
    }

    private fun handleBackupCall(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "savePreparedFile") {
            result.notImplemented()
            return
        }
        if (pendingSave != null) {
            result.error("backup_in_progress", "Another backup save is already active.", null)
            return
        }

        val sourcePath = call.argument<String>("sourcePath")
        val fileName = call.argument<String>("fileName")
        val mimeType = call.argument<String>("mimeType") ?: "application/octet-stream"
        if (sourcePath.isNullOrBlank() || fileName.isNullOrBlank() || !File(sourcePath).isFile) {
            result.error("invalid_backup_file", "Prepared backup file is unavailable.", null)
            return
        }

        pendingSave = PendingSave(sourcePath, result)
        val intent = Intent(Intent.ACTION_CREATE_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = mimeType
            putExtra(Intent.EXTRA_TITLE, fileName)
            addFlags(Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
        }
        try {
            startActivityForResult(intent, CREATE_DOCUMENT_REQUEST)
        } catch (error: Exception) {
            pendingSave = null
            result.error("document_picker_failed", error.message, null)
        }
    }

    @Deprecated("Deprecated in Android API, retained for FlutterActivity compatibility")
    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        if (requestCode != CREATE_DOCUMENT_REQUEST) return

        val save = pendingSave ?: return
        if (resultCode != Activity.RESULT_OK || data?.data == null) {
            pendingSave = null
            save.result.success(null)
            return
        }

        val destination = data.data!!
        Thread {
            try {
                BufferedInputStream(FileInputStream(save.sourcePath)).use { input ->
                    contentResolver.openOutputStream(destination)?.let { outputStream ->
                        BufferedOutputStream(outputStream).use { output -> input.copyTo(output) }
                    } ?: throw IllegalStateException("Unable to open the selected destination.")
                }
                mainHandler.post {
                    pendingSave = null
                    save.result.success(destination.toString())
                }
            } catch (error: Exception) {
                mainHandler.post {
                    pendingSave = null
                    save.result.error("backup_write_failed", error.message, null)
                }
            }
        }.start()
    }

    override fun onDestroy() {
        pendingSave?.result?.error("activity_destroyed", "Backup save was interrupted.", null)
        pendingSave = null
        super.onDestroy()
    }
}
