package app.yann.habitudes

import kotlinx.coroutines.delay

suspend fun <T> retryOnIllegalState(retryDelaysMs: LongArray, block: suspend () -> T): T? {
    var attempt = 0
    while (true) {
        try {
            return block()
        } catch (e: IllegalStateException) {
            if (attempt >= retryDelaysMs.size) return null
            delay(retryDelaysMs[attempt])
            attempt++
        }
    }
}
