package com.voltexchange.api.entity;

import com.fasterxml.jackson.annotation.JsonIgnoreProperties;
import jakarta.persistence.*;
import lombok.*;
import org.hibernate.annotations.JdbcTypeCode;
import org.hibernate.type.SqlTypes;

import java.math.BigDecimal;
import java.time.LocalDateTime;
import java.util.Map;

@Entity
@Table(name = "leituras")
@Getter
@Setter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Leitura {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    @Column(name = "leitura_id")
    private Long leituraId;

    @Column(name = "data_hora", nullable = false)
    private LocalDateTime dataHora;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "contador_id", nullable = false)
    @JsonIgnoreProperties({"utilizador", "leituras"})
    private Contador contador;

    @Column(name = "kwh_leitura", nullable = false, precision = 10, scale = 3)
    private BigDecimal kwhLeitura;

    @JdbcTypeCode(SqlTypes.JSON)
    @Column(name = "dados_audit", columnDefinition = "jsonb")
    private Map<String, Object> dadosAudit;
}