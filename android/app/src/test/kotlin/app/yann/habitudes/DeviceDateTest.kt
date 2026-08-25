package app.yann.habitudes

import java.util.TimeZone
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Before
import org.junit.Test

class DeviceDateTest {

    private var originalTimeZone: TimeZone? = null

    @Before
    fun setUp() {
        originalTimeZone = TimeZone.getDefault()
    }

    @After
    fun tearDown() {
        TimeZone.setDefault(originalTimeZone)
    }

    @Test
    fun epochZeroIsFirstLocalDay() {
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/Paris"))
        assertEquals("1970-01-01", deviceDateText(0L))
    }

    @Test
    fun padsMonthAndDayFields() {
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/Paris"))
        assertEquals("1970-01-05", deviceDateText(345600000L))
    }

    @Test
    fun lateUtcEveningRollsIntoNextLocalDay() {
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/Paris"))
        // 2026-08-25T22:30Z = 2026-08-26T00:30 CEST: the local day leads UTC.
        assertEquals("2026-08-26", deviceDateText(1787697000000L))
    }

    @Test
    fun utcMidnightIsAlreadyNextLocalDayInPositiveOffset() {
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/Paris"))
        // 2026-08-24T00:00Z = 2026-08-24T02:00 CEST.
        assertEquals("2026-08-24", deviceDateText(1787529600000L))
    }

    @Test
    fun negativeEpochRollsBackToPreviousLocalYear() {
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/Paris"))
        // 1969-12-31T23:59:59Z = 1970-01-01T00:59:59 CET.
        assertEquals("1970-01-01", deviceDateText(-1L))
    }

    @Test
    fun followsDeviceTimezone() {
        // 2026-08-24T12:00Z: same day in Paris, next day in Kiritimati (UTC+14).
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/Paris"))
        assertEquals("2026-08-24", deviceDateText(1787572800000L))
        TimeZone.setDefault(TimeZone.getTimeZone("Pacific/Kiritimati"))
        assertEquals("2026-08-25", deviceDateText(1787572800000L))
    }

    @Test
    fun dstTransitionDayKeepsLocalDay() {
        TimeZone.setDefault(TimeZone.getTimeZone("Europe/Paris"))
        // 2026-10-24T23:30Z = 2026-10-25T01:30 CEST (CEST->CET fall-back day).
        assertEquals("2026-10-25", deviceDateText(1792884600000L))
    }
}
