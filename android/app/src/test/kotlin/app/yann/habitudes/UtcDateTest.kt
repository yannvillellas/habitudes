package app.yann.habitudes

import java.util.TimeZone
import org.junit.Assert.assertEquals
import org.junit.Test

class UtcDateTest {

    @Test
    fun epochZeroIsFirstUtcDay() {
        assertEquals("1970-01-01", utcDateText(0L))
    }

    @Test
    fun fourDaysAfterEpochIsPadded() {
        assertEquals("1970-01-05", utcDateText(345600000L))
    }

    @Test
    fun lateEveningUtcIsSameDay() {
        assertEquals("2026-08-23", utcDateText(1787520600000L))
    }

    @Test
    fun midnightUtcStartsNewDay() {
        assertEquals("2026-08-24", utcDateText(1787529600000L))
    }

    @Test
    fun negativeEpochRollsBackToPreviousYear() {
        assertEquals("1969-12-31", utcDateText(-1L))
    }

    @Test
    fun resultIsIndependentOfDefaultTimeZone() {
        val original = TimeZone.getDefault()
        try {
            TimeZone.setDefault(TimeZone.getTimeZone("Pacific/Kiritimati"))
            assertEquals("2026-08-23", utcDateText(1787520600000L))
        } finally {
            TimeZone.setDefault(original)
        }
    }
}
