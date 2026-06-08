package com.rhyn.reach.core.utils

import android.content.Context
import android.net.Uri
import android.provider.OpenableColumns
import android.util.Log

import java.io.File
import java.io.InputStream
import java.util.UUID
import javax.inject.Inject
import javax.inject.Singleton
import androidx.core.net.toUri

@Singleton
class FileHelper @Inject constructor(
    private val context: Context
) {
    private val tag = "FileHelper"

    private val secureCacheDir = File(context.cacheDir, "reach_secure_cache").apply { mkdirs() }
    private val mediaDir = File(context.filesDir, "reach_media").apply { mkdirs() }

    fun getInputStreamFromUri(uriString: String): InputStream? {
        return try {
            val uri = uriString.toUri()
            context.contentResolver.openInputStream(uri)
        } catch (e: Exception) {
            Log.e(tag, "Failed to open input stream for URI: $uriString", e)
            null
        }
    }

    // --- NEW: EXTRACT REAL FILENAME ---
    fun getFileName(uriString: String): String {
        val uri = uriString.toUri()
        var result: String? = null
        if (uri.scheme == "content") {
            try {
                context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                    if (cursor.moveToFirst()) {
                        result = cursor.getString(cursor.getColumnIndexOrThrow(OpenableColumns.DISPLAY_NAME))
                    }
                }
            } catch (e: Exception) {
                Log.e(tag, "Failed to get file name", e)
            }
        }
        return result ?: uri.lastPathSegment ?: "unknown_file_${System.currentTimeMillis()}"
    }

    // --- UPDATED: COPY WITH REAL FILENAME ---
    fun copyUriToInternalStorage(uriString: String, fileName: String): String? {
        return try {
            val inputStream = getInputStreamFromUri(uriString) ?: return null

            // Create permanent file with the real name
            val internalFile = File(mediaDir, "${UUID.randomUUID()}_$fileName")
            val outputStream = java.io.FileOutputStream(internalFile)

            inputStream.use { input ->
                outputStream.use { output ->
                    input.copyTo(output)
                }
            }

            getInternalUriForFile(internalFile)
        } catch (e: Exception) {
            Log.e(tag, "Failed to copy URI to internal storage", e)
            null
        }
    }

    fun createTempEncryptedFile(): File {
        return File(secureCacheDir, "${UUID.randomUUID()}_encrypted.bin")
    }

    fun createDecryptedMediaFile(extension: String = "bin"): File {
        return File(mediaDir, "${UUID.randomUUID()}.$extension")
    }

    fun getInternalUriForFile(file: File): String {
        return Uri.fromFile(file).toString()
    }

    fun clearCache() {
        try {
            secureCacheDir.listFiles()?.forEach { it.delete() }
        } catch (e: Exception) {
            Log.w(tag, "Failed to clear secure cache directory.", e)
        }
    }

    fun deleteSecureCacheFile(fileName: String) {
        val file = File(secureCacheDir, fileName)
        if (file.exists()) {
            file.delete()
        }
    }

    fun getFileSize(uriString: String): Long {
        val uri = uriString.toUri()
        if (uri.scheme == "file") {
            return File(uri.path ?: "").length()
        }
        var size: Long = 0
        try {
            context.contentResolver.query(uri, null, null, null, null)?.use { cursor ->
                if (cursor.moveToFirst()) {
                    val sizeIndex = cursor.getColumnIndex(OpenableColumns.SIZE)
                    if (sizeIndex != -1) {
                        size = cursor.getLong(sizeIndex)
                    }
                }
            }
        } catch (e: Exception) {}
        return size
    }
}