package dev.brackenward.storage

import org.junit.Assert.assertArrayEquals
import org.junit.Test
import java.io.ByteArrayInputStream

class BoundedDocumentsTest {
    @Test fun exactLimit() {
        val bytes = ByteArray(9000) { (it % 251).toByte() }
        assertArrayEquals(bytes, BoundedDocuments.read(ByteArrayInputStream(bytes), bytes.size))
    }

    @Test(expected = IllegalArgumentException::class) fun overflowRejected() {
        BoundedDocuments.read(ByteArrayInputStream(ByteArray(8193)), 8192)
    }

    @Test(expected = IllegalArgumentException::class) fun excessiveLimitRejected() {
        BoundedDocuments.read(ByteArrayInputStream(byteArrayOf()), BoundedDocuments.MAX_BYTES + 1)
    }

    @Test fun emptyStream() {
        assertArrayEquals(byteArrayOf(), BoundedDocuments.read(ByteArrayInputStream(byteArrayOf()), 1))
    }
}
