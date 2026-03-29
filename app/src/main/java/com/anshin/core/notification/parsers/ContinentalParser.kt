package com.anshin.core.notification.parsers

import com.anshin.core.notification.BankParser
import com.anshin.core.notification.model.ParsedNotificationTransaction

class ContinentalParser : BankParser {
    private val amountRegex = Regex("""G\.\s*([\d.,]+)""", RegexOption.IGNORE_CASE)
    private val merchantRegex = Regex("""-\s*([A-Z0-9ÁÉÍÓÚÑ.\s]+)$""", RegexOption.IGNORE_CASE)

    override fun canHandle(packageName: String, title: String, text: String): Boolean {
        return packageName == "py.continental.banca" || title.contains("continental", ignoreCase = true)
    }

    override fun parse(title: String, text: String): ParsedNotificationTransaction? {
        val amount = amountRegex.find(text)?.groupValues?.getOrNull(1)?.let(::parseMoneyAmount) ?: return null
        val merchant = merchantRegex.find(text)?.groupValues?.getOrNull(1)?.let(::normalizeMerchant)
        val isIncome = text.contains("acredit", ignoreCase = true)

        return ParsedNotificationTransaction(
            amount = amount,
            merchant = merchant,
            source = "continental",
            isIncome = isIncome
        )
    }
}
