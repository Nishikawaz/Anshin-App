package com.anshin.core.notification

import com.anshin.core.notification.model.ParsedNotificationTransaction

interface BankParser {
    fun canHandle(packageName: String, title: String, text: String): Boolean

    fun parse(title: String, text: String): ParsedNotificationTransaction?
}
