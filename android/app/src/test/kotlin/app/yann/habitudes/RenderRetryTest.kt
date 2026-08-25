package app.yann.habitudes

import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.fail
import org.junit.Test

class RenderRetryTest {

    private val shortDelays = longArrayOf(1, 1)

    @Test
    fun returnsValueOnFirstAttempt() = runBlocking {
        var calls = 0
        val result = retryOnIllegalState(shortDelays) {
            calls++
            "ok"
        }

        assertEquals("ok", result)
        assertEquals(1, calls)
    }

    @Test
    fun retriesAfterIllegalStateException() = runBlocking {
        var calls = 0
        val result = retryOnIllegalState(shortDelays) {
            calls++
            if (calls == 1) throw IllegalStateException("Another session for 3 has started")
            "ok"
        }

        assertEquals("ok", result)
        assertEquals(2, calls)
    }

    @Test
    fun givesUpAfterExhaustingRetries() = runBlocking {
        var calls = 0
        val result = retryOnIllegalState(shortDelays) {
            calls++
            throw IllegalStateException("Another session for 3 has started")
        }

        assertNull(result)
        assertEquals(3, calls)
    }

    @Test
    fun doesNotRetryOtherExceptions() = runBlocking {
        var calls = 0
        try {
            retryOnIllegalState(shortDelays) {
                calls++
                throw RuntimeException("boom")
            }
            fail("expected RuntimeException to propagate")
        } catch (_: RuntimeException) {
            // expected
        }

        assertEquals(1, calls)
    }

    @Test
    fun emptyDelaysMeansSingleAttempt() = runBlocking {
        var calls = 0
        val result = retryOnIllegalState(longArrayOf()) {
            calls++
            throw IllegalStateException("Another session for 3 has started")
        }

        assertNull(result)
        assertEquals(1, calls)
    }
}
