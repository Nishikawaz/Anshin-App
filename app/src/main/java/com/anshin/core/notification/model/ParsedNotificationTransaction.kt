package com.anshin.core.notification.model

data class ParsedNotificationTransaction(
    val amount: Long,
    val merchant: String?,
    val source: String,
    val isIncome: Boolean = false,
    val isConfirmed: Boolean = true
)
