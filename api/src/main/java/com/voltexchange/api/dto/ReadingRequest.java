package com.voltexchange.api.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;
import java.util.Map;

@Data
public class ReadingRequest {
    @NotNull(message = "Leitura kWh é obrigatória")
    @Positive(message = "Leitura kWh deve ser positiva")
    private BigDecimal kwhLeitura;

    // Dados técnicos em JSON livre
    // Ex: {"temperatura": 45, "voltagem": 230, "erro_codigo": null}
    private Map<String, Object> dadosAudit;
}
