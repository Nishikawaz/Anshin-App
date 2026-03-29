package com.anshin.core.notification.parsers

import com.anshin.core.notification.BankParser
import com.anshin.core.notification.model.ParsedNotificationTransaction

class ItauParser : BankParser {
    private val amountRegex = Regex("""(?:G\.|PYG|Gs\.?)\s*([\d.,]+)""", RegexOption.IGNORE_CASE)
    private val merchantRegex = Regex("""en\s+([A-Z0-9ÁÉÍÓÚÑ.\s]+?)(?:\.|$)""", RegexOption.IGNORE_CASE)

    override fun canHandle(packageName: String, title: String, text: String): Boolean {
        return packageName == "com.itau.py" || title.contains("Itaú", ignoreCase = true)
    }

    override fun parse(title: String, text: String): ParsedNotificationTransaction? {
        val amount = amountRegex.find(text)?.groupValues?.getOrNull(1)?.let(::parseMoneyAmount) ?: return null
        val merchant = merchantRegex.find(text)?.groupValues?.getOrNull(1)?.let(::normalizeMerchant)
        val isIncome = text.contains("recibiste", ignoreCase = true)

        return ParsedNotificationTransaction(
            amount = amount,
            merchant = merchant,
            source = "itau",
            isIncome = isIncome
        )
    }
}
