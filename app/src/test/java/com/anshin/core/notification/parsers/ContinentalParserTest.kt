package com.anshin.core.notification.parsers

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class ContinentalParserTest {
    private val parser = ContinentalParser()

    @Test
    fun `continental parser extracts amount and merchant from debit notification`() {
        val result = parser.parse(
            title = "Continental",
            text = "Débito G. 45.000 - FARMACITY PY"
        )

        assertThat(result).isNotNull()
        assertThat(result?.amount).isEqualTo(45_000L)
        assertThat(result?.merchant).isEqualTo("FARMACITY PY")
        assertThat(result?.isIncome).isFalse()
    }
}
