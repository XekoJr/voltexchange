package com.voltexchange.api.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "ordenscompra")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class OrdemCompra {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "ordem_id")
    private Integer ordemId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "comprador_id", nullable = false)
    @JsonIgnoreProperties({"contadores", "ofertasVenda", "ordensCompra"})
    private Utilizador comprador;

    @Column(name = "quantidade_kwh", nullable = false, precision = 10, scale = 3)
    private BigDecimal quantidadeKwh;

    @Column(name = "preco_maximo", nullable = false, precision = 8, scale = 4)
    private BigDecimal precoMaximo;

    @Column(name = "estado", length = 20)
    @Builder.Default
    private String estado = "PENDENTE";

    @Column(name = "data_criacao", updatable = false)
    private LocalDateTime dataCriacao;

    @Column(name = "regiao", length = 100)
    private String regiao;

    @JsonIgnore
    @OneToMany(mappedBy = "ordemCompra", fetch = FetchType.LAZY)
    private List<Transacao> transacoes;

    @PrePersist
    protected void onCreate() {
        this.dataCriacao = LocalDateTime.now();
    }
}