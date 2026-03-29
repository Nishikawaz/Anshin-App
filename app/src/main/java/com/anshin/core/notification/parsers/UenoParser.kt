package com.anshin.core.notification.parsers

import com.anshin.core.notification.BankParser
import com.anshin.core.notification.model.ParsedNotificationTransaction

class UenoParser : BankParser {
    private val amountRegex = Regex("""G\s+([\d.,]+)""", RegexOption.IGNORE_CASE)
    private val merchantRegex = Regex("""(?:a|en)\s+([^.]+)""", RegexOption.IGNORE_CASE)

    override fun canHandle(packageName: String, title: String, text: String): Boolean {
        return packageName == "py.ueno.app" || title.contains("ueno", ignoreCase = true)
    }

    override fun parse(title: String, text: String): ParsedNotificationTransaction? {
        val amount = amountRegex.find(text)?.groupValues?.getOrNull(1)?.let(::parseMoneyAmount) ?: return null
        val merchant = merchantRegex.find(text)?.groupValues?.getOrNull(1)?.let(::normalizeMerchant)
        val isIncome = text.contains("recibiste", ignoreCase = true)

        return ParsedNotificationTransaction(
            amount = amount,
            merchant = merchant,
            source = "ueno",
            isIncome = isIncome
        )
    }
}
