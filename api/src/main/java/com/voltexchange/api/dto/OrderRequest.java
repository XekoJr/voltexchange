package com.voltexchange.api.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class OrderRequest {

    @NotNull(message = "Quantidade é obrigatória")
    @Positive(message = "Quantidade deve ser positiva")
    private BigDecimal quantidadeKwh;

    @NotNull(message = "Preço máximo é obrigatório")
    @Positive(message = "Preço máximo deve ser positivo")
    private BigDecimal precoMaximo;

    // Opcional — preferência de região para o matching engine
    private String regiao;
}
