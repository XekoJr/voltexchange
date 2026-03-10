package com.voltexchange.api.entity;

import com.fasterxml.jackson.annotation.JsonIgnore;
import jakarta.persistence.*;
import lombok.*;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.List;

@Entity
@Table(name = "utilizadores")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Utilizador {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "utilizador_id")
    private Integer utilizadorId;

    @Column(name = "nome", nullable = false, length = 200)
    private String nome;

    @Column(name = "email", nullable = false, unique = true, length = 255)
    private String email;

    @JsonIgnore
    @Column(name = "password_hash", nullable = false, length = 255)
    private String passwordHash;

    @Column(name = "saldo", precision = 12, scale = 2)
    @Builder.Default
    private BigDecimal saldo = BigDecimal.ZERO;

    @Column(name = "data_criacao", updatable = false)
    private LocalDateTime dataCriacao;

    @Column(name = "ultimo_acesso")
    private LocalDateTime ultimoAcesso;

    @JsonIgnore
    @OneToMany(mappedBy = "utilizador", fetch = FetchType.LAZY)
    private List<Contador> contadores;

    @JsonIgnore
    @OneToMany(mappedBy = "vendedor", fetch = FetchType.LAZY)
    private List<OfertaVenda> ofertasVenda;

    @JsonIgnore
    @OneToMany(mappedBy = "comprador", fetch = FetchType.LAZY)
    private List<OrdemCompra> ordensCompra;

    @PrePersist
    protected void onCreate() {
        this.dataCriacao = LocalDateTime.now();
    }
}