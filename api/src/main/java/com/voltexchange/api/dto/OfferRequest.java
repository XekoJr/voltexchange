package com.voltexchange.api.dto;

import jakarta.validation.constraints.NotNull;
import jakarta.validation.constraints.Positive;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class OfferRequest {

    @NotNull(message = "Quantidade kWh é obrigatória")
    @Positive(message = "Quantidade deve ser positiva")
    private BigDecimal quantidadeKwh;

    @NotNull(message = "Preço unitário é obrigatório")
    @Positive(message = "Preço deve ser positivo")
    private BigDecimal precoUnitario;

    private String regiao;
}
