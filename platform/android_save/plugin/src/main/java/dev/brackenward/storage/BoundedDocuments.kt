package dev.brackenward.storage

import java.io.ByteArrayOutputStream
import java.io.InputStream

/** No provider paths or credentials enter diagnostics. Limits apply while streaming. */
object BoundedDocuments {
    const val MAX_BYTES = 64 * 1024 * 1024

    fun read(input: InputStream, limit: Int): ByteArray {
        require(limit in 1..MAX_BYTES) { "invalid_limit" }
        val output = ByteArrayOutputStream(minOf(limit, 8192))
        val chunk = ByteArray(8192)
        while (true) {
            val count = input.read(chunk)
            if (count < 0) break
            if (count == 0) continue
            require(output.size().toLong() + count <= limit.toLong()) { "too_large" }
            output.write(chunk, 0, count)
        }
        return output.toByteArray()
    }
}
