package com.voltexchange.api.service;

import com.voltexchange.api.dto.BuyRequest;
import com.voltexchange.api.dto.OfferRequest;
import com.voltexchange.api.dto.OrderRequest;
import com.voltexchange.api.entity.OfertaVenda;
import com.voltexchange.api.entity.OrdemCompra;
import com.voltexchange.api.repository.OfertaVendaRepository;
import com.voltexchange.api.repository.OrdemCompraRepository;
import com.voltexchange.api.repository.UtilizadorRepository;
import jakarta.annotation.PostConstruct;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.jdbc.core.simple.SimpleJdbcCall;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import javax.sql.DataSource;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

@Slf4j
@Service
@RequiredArgsConstructor
public class MarketService {

    private final OfertaVendaRepository ofertaVendaRepository;
    private final OrdemCompraRepository ordemCompraRepository;
    private final UtilizadorRepository utilizadorRepository;
    private final DataSource dataSource;
    // SimpleJdbcCall para chamar stored procedures PostgreSQL
    // Inicializado no @PostConstruct para garantir que o DataSource está pronto
    private SimpleJdbcCall compraDiretaCall;
    private SimpleJdbcCall matchingEngineCall;

    @PostConstruct
    public void init() {
        // sp_ExecutarCompraDireta(p_oferta_id, p_comprador_id, p_quantidade)
        compraDiretaCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_executarcompradireta");

        // sp_MatchingEngine()
        matchingEngineCall = new SimpleJdbcCall(dataSource)
                .withProcedureName("sp_matchingengine");
    }

    @Transactional
    public OfertaVenda criarOferta(OfferRequest request, String emailVendedor) {
        log.info("Criar oferta de venda: vendedor={}, quantidade={}",
                emailVendedor, request.getQuantidadeKwh());

        var vendedor = utilizadorRepository.findByEmail(emailVendedor)
                .orElseThrow(() -> new RuntimeException("Utilizador não encontrado"));

        OfertaVenda oferta = OfertaVenda.builder()
                .vendedor(vendedor)
                .quantidadeKwh(request.getQuantidadeKwh())
                .precoUnitario(request.getPrecoUnitario())
                .regiao(request.getRegiao())
                .estado("ATIVA")
                .build();

        OfertaVenda saved = ofertaVendaRepository.save(oferta);
        log.info("Oferta criada: id={}", saved.getOfertaId());
        return saved;
    }

    /**
     * POST /api/market/offers/{ofertaId}/buy — Compra imediata.
     * Chama sp_ExecutarCompraDireta na BD que garante ACID:
     * SELECT FOR UPDATE → verifica estado → debita comprador → credita vendedor → regista transação.
     */
    @Transactional
    public Map<String, Object> executarCompraDireta(Integer ofertaId, BuyRequest request, String emailComprador) {
        log.info("Compra direta: oferta={}, comprador={}", ofertaId, emailComprador);

        // Obter ID do comprador a partir do email extraído do JWT
        var comprador = utilizadorRepository.findByEmail(emailComprador)
                .orElseThrow(() -> new RuntimeException("Utilizador não encontrado"));

        // Chamar stored procedure — toda a lógica ACID está na BD
        Map<String, Object> params = new HashMap<>();
        params.put("p_oferta_id", ofertaId);
        params.put("p_comprador_id", comprador.getUtilizadorId());
        params.put("p_quantidade", request.getQuantidade());

        try {
            compraDiretaCall.execute(params);
        } catch (Exception e) {
            // Mensagens de erro vêm da BD (ex: "Saldo insuficiente", "Oferta não está ativa")
            log.error("Erro na compra direta: {}", e.getMessage());
            throw new RuntimeException(extrairMensagemErro(e));
        }

        log.info("Compra direta executada com sucesso: oferta={}", ofertaId);
        return Map.of(
                "mensagem", "Compra realizada com sucesso",
                "ofertaId", ofertaId,
                "quantidade", request.getQuantidade()
        );
    }

    /**
     * POST /api/market/order — Criar ordem de compra futura.
     * Insere na tabela OrdensCompra.
     * Se o trigger de auto-matching estiver ativo, a sp_MatchingEngine
     * é disparada automaticamente após o INSERT.
     */
    @Transactional
    public OrdemCompra criarOrdemCompra(OrderRequest request, String emailComprador) {
        log.info("Criar ordem de compra: comprador={}, quantidade={}",
                emailComprador, request.getQuantidadeKwh());

        var comprador = utilizadorRepository.findByEmail(emailComprador)
                .orElseThrow(() -> new RuntimeException("Utilizador não encontrado"));

        OrdemCompra ordem = OrdemCompra.builder()
                .comprador(comprador)
                .quantidadeKwh(request.getQuantidadeKwh())
                .precoMaximo(request.getPrecoMaximo())
                .regiao(request.getRegiao())
                .estado("PENDENTE")
                .build();

        OrdemCompra saved = ordemCompraRepository.save(ordem);
        log.info("Ordem de compra criada: id={}", saved.getOrdemId());
        return saved;
    }

    /**
     * POST /api/market/match — Disparar matching engine manualmente.
     * OBRIGATÓRIO pelo enunciado para o docente forçar execução durante avaliação,
     * mesmo que o trigger automático esteja implementado.
     */
    @Transactional
    public void executarMatching() {
        log.info("Disparar sp_MatchingEngine manualmente");
        try {
            matchingEngineCall.execute();
            log.info("sp_MatchingEngine executada com sucesso");
        } catch (Exception e) {
            log.error("Erro no matching engine: {}", e.getMessage());
            throw new RuntimeException("Erro ao executar matching engine: " + e.getMessage());
        }
    }

    /**
     * GET /api/market/offers — Listar ofertas ativas.
     * Suporta filtro opcional por região.
     */
    @Transactional(readOnly = true)
    public List<OfertaVenda> listarOfertasAtivas(String regiao) {
        if (regiao != null && !regiao.isBlank()) {
            return ofertaVendaRepository
                    .findByEstadoAndRegiaoOrderByPrecoUnitarioAsc("ATIVA", regiao);
        }
        return ofertaVendaRepository.findByEstadoOrderByPrecoUnitarioAsc("ATIVA");
    }

    // Extrair mensagem legível dos erros do PostgreSQL
    private String extrairMensagemErro(Exception e) {
        String msg = e.getMessage();
        if (msg != null && msg.contains("ERROR:")) {
            int idx = msg.indexOf("ERROR:") + 6;
            int end = msg.indexOf("\n", idx);
            return end > 0 ? msg.substring(idx, end).trim() : msg.substring(idx).trim();
        }
        return msg;
    }
}
