package com.voltexchange.api.controller;

import com.voltexchange.api.dto.BuyRequest;
import com.voltexchange.api.dto.OfferRequest;
import com.voltexchange.api.dto.OrderRequest;
import com.voltexchange.api.entity.OfertaVenda;
import com.voltexchange.api.entity.OrdemCompra;
import com.voltexchange.api.service.MarketService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/market")
@RequiredArgsConstructor
public class MarketController {

    private final MarketService marketService;

    /**
     * GET /api/market/offers?regiao=Norte
     * Lista ofertas de venda ativas, ordenadas por preço crescente.
     * Parâmetro 'regiao' é opcional.
     * Requer: Authorization: Bearer <token>
     */
    @GetMapping("/offers")
    public ResponseEntity<List<OfertaVenda>> listarOfertas(
            @RequestParam(required = false) String regiao) {

        log.debug("GET /api/market/offers - regiao: {}", regiao);
        return ResponseEntity.ok(marketService.listarOfertasAtivas(regiao));
    }

    /**
     * POST /api/market/offers
     * Cria uma nova oferta de venda de energia.
     * Requer: Authorization: Bearer <token>
     *
     * Body: { "quantidadeKwh": 50.0, "precoUnitario": 0.12, "regiao": "Norte" }
     */
    @PostMapping("/offers")
    public ResponseEntity<OfertaVenda> criarOferta(
            @Valid @RequestBody OfferRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        log.debug("POST /api/market/offers - vendedor: {}", userDetails.getUsername());
        OfertaVenda oferta = marketService.criarOferta(request, userDetails.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED).body(oferta);
    }

    /**
     * POST /api/market/offers/{ofertaId}/buy
     * Compra imediata — chama sp_ExecutarCompraDireta na BD.
     * A stored procedure garante ACID: bloqueia a oferta, verifica estado,
     * debita comprador, credita vendedor e regista a transação atomicamente.
     * Requer: Authorization: Bearer <token>
     *
     * Body: { "quantidade": 10.5 }
     */
    @PostMapping("/offers/{ofertaId}/buy")
    public ResponseEntity<Map<String, Object>> comprarDireto(
            @PathVariable Integer ofertaId,
            @Valid @RequestBody BuyRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        log.debug("POST /api/market/offers/{}/buy - comprador: {}",
                ofertaId, userDetails.getUsername());

        Map<String, Object> resultado = marketService.executarCompraDireta(
                ofertaId, request, userDetails.getUsername());
        return ResponseEntity.ok(resultado);
    }

    /**
     * POST /api/market/order
     * Cria uma ordem de compra futura na tabela OrdensCompra.
     * Se o trigger de auto-matching estiver ativo na BD,
     * a sp_MatchingEngine é disparada automaticamente após este INSERT.
     * Requer: Authorization: Bearer <token>
     *
     * Body: { "quantidadeKwh": 20.0, "precoMaximo": 0.15, "regiao": "Norte" }
     */
    @PostMapping("/order")
    public ResponseEntity<OrdemCompra> criarOrdem(
            @Valid @RequestBody OrderRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        log.debug("POST /api/market/order - comprador: {}", userDetails.getUsername());
        OrdemCompra ordem = marketService.criarOrdemCompra(request, userDetails.getUsername());
        return ResponseEntity.status(HttpStatus.CREATED).body(ordem);
    }

    /**
     * POST /api/market/match
     * Dispara a sp_MatchingEngine manualmente.
     * OBRIGATÓRIO pelo enunciado — permite ao docente forçar execução durante avaliação,
     * mesmo que o trigger automático (excelência) esteja implementado.
     * Requer: Authorization: Bearer <token>
     */
    @PostMapping("/match")
    public ResponseEntity<Map<String, Object>> dispararMatching() {
        log.info("POST /api/market/match - disparar matching engine manualmente");
        marketService.executarMatching();
        return ResponseEntity.ok(Map.of(
                "mensagem", "Matching engine executado com sucesso"
        ));
    }
}
