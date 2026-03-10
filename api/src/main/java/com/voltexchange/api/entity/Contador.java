package com.voltexchange.api.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;

import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "contadores")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Contador {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "contador_id")
    private Integer contadorId;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "utilizador_id", nullable = false)
    @JsonIgnoreProperties({"contadores", "ofertasVenda", "ordensCompra"})
    private Utilizador utilizador;

    @Column(name = "numero_serie", nullable = false, unique = true, length = 50)
    private String numeroSerie;

    @Column(name = "estado", length = 20)
    @Builder.Default
    private String estado = "ATIVO";

    @Column(name = "data_instalacao", updatable = false)
    private LocalDateTime dataInstalacao;

    @Column(name = "regiao", length = 100)
    private String regiao;

    @JsonIgnore
    @OneToMany(mappedBy = "contador", fetch = FetchType.LAZY)
    private List<Leitura> leituras;

    @PrePersist
    protected void onCreate() {
        this.dataInstalacao = LocalDateTime.now();
    }
}