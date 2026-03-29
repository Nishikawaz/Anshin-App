# Parsers de bancos — Documentación técnica

## Cómo funciona el sistema de parsers

Cada banco tiene su parser independiente. `BankNotificationService` itera la lista y usa el primero que retorne `canHandle() = true`.

```kotlin
private val parsers: List<BankParser> = listOf(
    ItauParser(),
    UenoParser(),
    ContinentalParser()
    // Agregar nuevos bancos acá
)
```

---

## Itaú Paraguay

**Package:** `com.itau.py` (verificar en dispositivo real — puede variar)

### Formatos conocidos

| Tipo | Ejemplo |
|------|---------|
| Compra débito | `"Compra aprobada por G. 85.000 en STOCK S.A."` |
| Compra crédito | `"Compra con TC por G. 120.000 en SHOPPING DEL SOL"` |
| Transferencia salida | `"Transferencia de G. 500.000 realizada"` |
| Transferencia entrada | `"Recibiste G. 1.000.000 de JUAN PEREZ"` |

### Regex activos

```kotlin
// Montos en guaraníes
val AMOUNT_PYG = Regex("""(?:G\.|PYG|Gs\.?)\s*([\d.,]+)""", RegexOption.IGNORE_CASE)
// Comercio
val MERCHANT   = Regex("""en\s+([A-Z][A-Z0-9\s.]+?)(?:\.|$)""")
```

### Edge cases conocidos

- Los puntos en el monto son separadores de miles: `85.000` → `85000`
- El comercio a veces incluye el número de terminal al final (ignorarlo)
- Las transferencias no tienen comercio — `merchant = null`

---

## Ueno

**Package:** `py.ueno.app` (verificar — Ueno actualiza frecuentemente)

### Formatos conocidos

| Tipo | Ejemplo |
|------|---------|
| Pago | `"Pagaste G 50.000 a Farmacia Central"` |
| Recarga | `"Recargaste G 100.000"` |
| Transferencia | `"Enviaste G 200.000 a María García"` |

### Regex activos

```kotlin
val AMOUNT_PYG = Regex("""G\s+([\d.,]+)""")
val MERCHANT   = Regex("""(?:a|en)\s+([^.]+)""")
```

### Edge cases conocidos

- Ueno usa `"G"` sin punto, Itaú usa `"G."` — el regex debe diferenciarlos
- Los pagos QR a veces no incluyen nombre del comercio

---

## Continental

**Package:** `py.continental.banca`

### Formatos conocidos

| Tipo | Ejemplo |
|------|---------|
| Débito | `"Débito G. 45.000 - FARMACITY PY"` |
| Crédito | `"Crédito TC G. 200.000 - EL DORADO SHOPPING"` |
| Débito automático | `"Débito automático G. 85.000 - PERSONAL S.A."` |

### Regex activos

```kotlin
val AMOUNT_PYG = Regex("""G\.\s*([\d.,]+)""")
val MERCHANT   = Regex("""-\s*([A-Z][^-]+)$""")
```

### Edge cases conocidos

- El guión `-` separa monto y comercio — parte del formato estable
- "Débito automático" indica gasto recurrente — categorizar como fijo

---

## Agregar un banco nuevo

1. Crear `NuevoBancoParser.kt` en `core/notification/parsers/`
2. Implementar `BankParser`:
   ```kotlin
   class NuevoBancoParser : BankParser {
       override fun canHandle(pkg: String, title: String, text: String): Boolean = ...
       override fun parse(title: String, text: String): TransactionEntity? = ...
   }
   ```
3. Registrar en `BankNotificationService.parsers`
4. Agregar tests en `NuevoBancoParserTest` con al menos 5 ejemplos reales
5. Actualizar `docs/bank-parsers.md` (este archivo)
6. Actualizar `docs/README.md` tabla de bancos

---

## Monitoreo de parsers rotos

Si un banco cambia su formato, los gastos dejan de registrarse silenciosamente.

**Sistema de detección:**
- `ParseFailureTracker` cuenta cuántas notificaciones del package no matchean ningún parser
- Si supera el umbral (configurable en Remote Config: `parser_failure_threshold = 5`) en 24h
- Envía evento a Firebase Analytics: `parser_failure {bank: "itau", count: 8}`
- Dashboard en Firebase → alertar al equipo

**Fallback al usuario:**
```
"Recibimos una notificación de Itaú que no pudimos procesar.
 ¿Querés registrar el gasto manualmente?"
```
