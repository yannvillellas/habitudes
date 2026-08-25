package app.yann.habitudes

import java.util.Calendar
import java.util.Locale

fun deviceDateText(epochMillis: Long): String {
    val calendar = Calendar.getInstance()
    calendar.timeInMillis = epochMillis
    return String.format(
        Locale.US,
        "%04d-%02d-%02d",
        calendar.get(Calendar.YEAR),
        calendar.get(Calendar.MONTH) + 1,
        calendar.get(Calendar.DAY_OF_MONTH),
    )
}
