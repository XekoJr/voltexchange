package com.voltexchange.api.repository;

import com.voltexchange.api.entity.OrdemCompra;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OrdemCompraRepository extends JpaRepository<OrdemCompra, Integer> {

    // Ordens pendentes — usadas pelo matching engine
    List<OrdemCompra> findByEstadoOrderByDataCriacaoAsc(String estado);

    // Ordens de um comprador
    List<OrdemCompra> findByCompradorUtilizadorId(Integer compradorId);
}
