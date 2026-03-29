package com.anshin.core.notification.parsers

import com.google.common.truth.Truth.assertThat
import org.junit.Test

class ItauParserTest {
    private val parser = ItauParser()

    @Test
    fun `itau parser extracts amount and merchant from purchase notification`() {
        val result = parser.parse(
            title = "Itaú",
            text = "Compra aprobada por G. 85.000 en STOCK S.A."
        )

        assertThat(result).isNotNull()
        assertThat(result?.amount).isEqualTo(85_000L)
        assertThat(result?.merchant).isEqualTo("STOCK S.A")
        assertThat(result?.isIncome).isFalse()
    }

    @Test
    fun `itau parser marks incoming transfer as income`() {
        val result = parser.parse(
            title = "Itaú",
            text = "Recibiste G. 1.000.000 de JUAN PEREZ"
        )

        assertThat(result?.amount).isEqualTo(1_000_000L)
        assertThat(result?.merchant).isNull()
        assertThat(result?.isIncome).isTrue()
    }
}
