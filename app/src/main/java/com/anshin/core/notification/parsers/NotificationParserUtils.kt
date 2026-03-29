package com.anshin.core.notification.parsers

internal fun parseMoneyAmount(raw: String): Long? {
    val normalized = raw
        .trim()
        .replace(".", "")
        .replace(",", "")

    return normalized.toLongOrNull()
}

internal fun normalizeMerchant(raw: String?): String? {
    return raw
        ?.trim()
        ?.trimEnd('.')
        ?.takeIf { it.isNotBlank() }
}
