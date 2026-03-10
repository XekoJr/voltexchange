package com.voltexchange.api.repository;

import com.voltexchange.api.entity.OfertaVenda;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface OfertaVendaRepository extends JpaRepository<OfertaVenda, Integer> {

    // Listar todas as ofertas ativas — endpoint GET /api/market/offers
    List<OfertaVenda> findByEstadoOrderByPrecoUnitarioAsc(String estado);

    // Ofertas ativas filtradas por região
    List<OfertaVenda> findByEstadoAndRegiaoOrderByPrecoUnitarioAsc(String estado, String regiao);

    // Ofertas de um vendedor específico
    List<OfertaVenda> findByVendedorUtilizadorId(Integer vendedorId);
}
