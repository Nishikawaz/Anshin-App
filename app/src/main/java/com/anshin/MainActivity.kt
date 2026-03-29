package com.anshin

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.anshin.presentation.theme.ActionGreen
import com.anshin.presentation.theme.AnshinTheme
import com.anshin.presentation.theme.BaseBackground
import com.anshin.presentation.theme.ForestGreen
import com.anshin.presentation.theme.PaleGreen
import com.anshin.presentation.theme.SoftGreen
import com.anshin.presentation.theme.SurfaceMuted
import com.anshin.presentation.theme.TextSecondary
import com.anshin.presentation.theme.WarmHighlight

class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContent {
            AnshinTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    HomeScreen()
                }
            }
        }
    }
}

@Composable
private fun HomeScreen() {
    Box(
        modifier = Modifier
            .fillMaxSize()
            .background(
                brush = Brush.verticalGradient(
                    colors = listOf(
                        PaleGreen.copy(alpha = 0.9f),
                        BaseBackground
                    )
                )
            )
    ) {
        Box(
            modifier = Modifier
                .padding(start = 220.dp, top = 20.dp)
                .width(190.dp)
                .height(190.dp)
                .clip(RoundedCornerShape(90.dp))
                .background(SoftGreen.copy(alpha = 0.12f))
        )

        Box(
            modifier = Modifier
                .padding(start = 20.dp, top = 520.dp)
                .width(150.dp)
                .height(150.dp)
                .clip(RoundedCornerShape(70.dp))
                .background(WarmHighlight.copy(alpha = 0.15f))
        )

        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(horizontal = 20.dp, vertical = 28.dp),
            verticalArrangement = Arrangement.SpaceBetween
        ) {
            HeaderCard()
            DashboardCard()
        }
    }
}

@Composable
private fun HeaderCard() {
    Card(
        colors = CardDefaults.cardColors(containerColor = ForestGreen),
        shape = RoundedCornerShape(28.dp),
        border = BorderStroke(1.dp, SoftGreen.copy(alpha = 0.3f))
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(22.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp)
        ) {
            Text(
                text = "Anshin",
                color = PaleGreen,
                style = MaterialTheme.typography.labelLarge
            )
            Text(
                text = "Disponible hoy",
                color = PaleGreen.copy(alpha = 0.9f),
                style = MaterialTheme.typography.titleMedium
            )
            Text(
                text = "Gs. 1.845.200",
                color = BaseBackground,
                style = MaterialTheme.typography.displaySmall,
                fontWeight = FontWeight.Bold
            )
            Text(
                text = "El orden es progreso.",
                color = PaleGreen.copy(alpha = 0.8f),
                style = MaterialTheme.typography.bodyMedium
            )
        }
    }
}

@Composable
private fun DashboardCard() {
    Card(
        colors = CardDefaults.cardColors(containerColor = BaseBackground),
        shape = RoundedCornerShape(28.dp),
        border = BorderStroke(1.dp, ActionGreen.copy(alpha = 0.18f))
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(22.dp),
            verticalArrangement = Arrangement.spacedBy(16.dp)
        ) {
            Text(
                text = "Resumen semanal",
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
            Text(
                text = "3 movimientos capturados automaticamente y un gasto por confirmar.",
                style = MaterialTheme.typography.bodyMedium,
                color = TextSecondary
            )

            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(10.dp)
            ) {
                MetricPill(
                    modifier = Modifier.weight(1f),
                    label = "Presupuesto",
                    value = "72%"
                )
                MetricPill(
                    modifier = Modifier.weight(1f),
                    label = "Racha",
                    value = "9 dias"
                )
            }

            Button(
                onClick = {},
                modifier = Modifier.fillMaxWidth(),
                shape = RoundedCornerShape(14.dp),
                colors = ButtonDefaults.buttonColors(
                    containerColor = ActionGreen,
                    contentColor = BaseBackground
                )
            ) {
                Text(
                    text = "Registrar movimiento",
                    style = MaterialTheme.typography.labelLarge,
                    modifier = Modifier.padding(vertical = 4.dp),
                    textAlign = TextAlign.Center
                )
            }
        }
    }
}

@Composable
private fun MetricPill(
    modifier: Modifier = Modifier,
    label: String,
    value: String
) {
    Card(
        modifier = modifier,
        colors = CardDefaults.cardColors(containerColor = SurfaceMuted),
        border = BorderStroke(1.dp, SoftGreen.copy(alpha = 0.26f)),
        shape = RoundedCornerShape(16.dp)
    ) {
        Column(
            modifier = Modifier.padding(horizontal = 12.dp, vertical = 14.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp)
        ) {
            Text(
                text = label,
                style = MaterialTheme.typography.labelMedium,
                color = TextSecondary
            )
            Text(
                text = value,
                style = MaterialTheme.typography.titleLarge,
                color = MaterialTheme.colorScheme.onSurface
            )
        }
    }
}
