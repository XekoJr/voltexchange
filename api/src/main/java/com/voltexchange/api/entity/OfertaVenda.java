package com.voltexchange.api.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "ofertasvenda")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OfertaVenda {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "oferta_id")
    private Integer ofertaId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "vendedor_id", nullable = false)
    @JsonIgnoreProperties({"contadores", "ofertasVenda", "ordensCompra"})
    private Utilizador vendedor;

    @Column(name = "quantidade_kwh", nullable = false, precision = 10, scale = 3)
    private BigDecimal quantidadeKwh;

    @Column(name = "preco_unitario", nullable = false, precision = 8, scale = 4)
    private BigDecimal precoUnitario;

    @Column(name = "estado", length = 20)
    @Builder.Default
    private String estado = "ATIVA";

    @Column(name = "data_criacao", updatable = false)
    private LocalDateTime dataCriacao;

    @Column(name = "data_expiracao")
    private LocalDateTime dataExpiracao;

    @Column(name = "regiao", length = 100)
    private String regiao;

    @JsonIgnore
    @OneToMany(mappedBy = "ofertaVenda", fetch = FetchType.LAZY)
    private List<Transacao> transacoes;

    @PrePersist
    protected void onCreate() {
        this.dataCriacao = LocalDateTime.now();
    }
}