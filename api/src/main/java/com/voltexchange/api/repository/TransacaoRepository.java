package com.voltexchange.api.repository;

import com.voltexchange.api.entity.Transacao;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TransacaoRepository extends JpaRepository<Transacao, Integer> {

    // Histórico de compras de um utilizador
    List<Transacao> findByCompradorUtilizadorIdOrderByDataTransacaoDesc(Integer compradorId);

    // Histórico de vendas de um utilizador
    List<Transacao> findByVendedorUtilizadorIdOrderByDataTransacaoDesc(Integer vendedorId);
}
