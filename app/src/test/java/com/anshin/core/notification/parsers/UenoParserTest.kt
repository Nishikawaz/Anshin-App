package com.anshin.core.notification.parsers

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class UenoParserTest {
    private val parser = UenoParser()

    @Test
    fun `ueno parser extracts amount and merchant from payment notification`() {
        val result = parser.parse(
            title = "Ueno",
            text = "Pagaste G 50.000 a Farmacia Central"
        )

        assertThat(result).isNotNull()
        assertThat(result?.amount).isEqualTo(50_000L)
        assertThat(result?.merchant).isEqualTo("Farmacia Central")
        assertThat(result?.isIncome).isFalse()
    }
}
