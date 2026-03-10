package com.voltexchange.api.repository;

import com.voltexchange.api.entity.Leitura;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.stereotype.Repository;

import java.time.LocalDateTime;
import java.util.List;

@Repository
public interface LeituraRepository extends JpaRepository<Leitura, Long> {

    @Query(value = """
            SELECT * FROM leituras
            WHERE contador_id = :contadorId
              AND data_hora BETWEEN :inicio AND :fim
            ORDER BY data_hora DESC
            """, nativeQuery = true)
    List<Leitura> findByContadorAndPeriodo(
            @Param("contadorId") Integer contadorId,
            @Param("inicio") LocalDateTime inicio,
            @Param("fim") LocalDateTime fim
    );

    @Query(value = """
            SELECT l.* FROM leituras l
            JOIN contadores c ON l.contador_id = c.contador_id
            WHERE (l.dados_audit->>'temperatura')::numeric > 80
               OR l.dados_audit ? 'erro_codigo'
            ORDER BY l.data_hora DESC
            LIMIT 100
            """, nativeQuery = true)
    List<Leitura> findAnomaliasRecentes();
}
