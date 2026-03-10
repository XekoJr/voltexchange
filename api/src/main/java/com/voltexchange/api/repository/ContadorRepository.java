package com.voltexchange.api.repository;

import com.voltexchange.api.entity.Contador;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;
import java.util.Optional;

@Repository
public interface ContadorRepository extends JpaRepository<Contador, Integer> {

    // Listar contadores de um utilizador
    List<Contador> findByUtilizadorUtilizadorId(Integer utilizadorId);

    // Buscar por número de série
    Optional<Contador> findByNumeroSerie(String numeroSerie);

    // Listar contadores em manutenção (anomalias detectadas)
    List<Contador> findByEstado(String estado);
}
