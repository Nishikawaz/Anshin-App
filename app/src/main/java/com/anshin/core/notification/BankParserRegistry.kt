package com.anshin.core.notification

import com.anshin.core.notification.parsers.ContinentalParser
import com.anshin.core.notification.parsers.ItauParser
import com.anshin.core.notification.parsers.UenoParser

object BankParserRegistry {
    val parsers: List<BankParser> = listOf(
        ItauParser(),
        UenoParser(),
        ContinentalParser()
    )
}
