package com.voltexchange.api.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "transacoes")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Transacao {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "transacao_id")
    private Integer transacaoId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "oferta_id", nullable = true)
    @JsonIgnoreProperties({"vendedor", "transacoes"})
    private OfertaVenda ofertaVenda;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "ordem_id", nullable = true)
    @JsonIgnoreProperties({"comprador", "transacoes"})
    private OrdemCompra ordemCompra;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "comprador_id", nullable = false)
    @JsonIgnoreProperties({"contadores", "ofertasVenda", "ordensCompra"})
    private Utilizador comprador;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vendedor_id", nullable = false)
    @JsonIgnoreProperties({"contadores", "ofertasVenda", "ordensCompra"})
    private Utilizador vendedor;

    @Column(name = "quantidade_kwh", nullable = false, precision = 10, scale = 3)
    private BigDecimal quantidadeKwh;

    @Column(name = "preco_unitario", nullable = false, precision = 8, scale = 4)
    private BigDecimal precoUnitario;

    @Column(name = "valor_total", nullable = false, precision = 12, scale = 2)
    private BigDecimal valorTotal;

    @Column(name = "data_transacao", updatable = false)
    private LocalDateTime dataTransacao;

    @Column(name = "tipo_transacao", length = 20)
    private String tipoTransacao;

    @PrePersist
    protected void onCreate() {
        this.dataTransacao = LocalDateTime.now();
    }
}