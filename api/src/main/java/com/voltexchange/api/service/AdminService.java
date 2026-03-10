package com.voltexchange.api.service;

import com.voltexchange.api.entity.Contador;
import com.voltexchange.api.entity.Leitura;
import com.voltexchange.api.repository.ContadorRepository;
import com.voltexchange.api.repository.LeituraRepository;
import com.voltexchange.api.repository.TransacaoRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Slf4j
@Service
@RequiredArgsConstructor
public class AdminService {

    private final LeituraRepository leituraRepository;
    private final ContadorRepository contadorRepository;
    private final TransacaoRepository transacaoRepository;

    /**
     * GET /api/admin/anomalies
     * Retorna leituras com anomalias JSONB agrupadas por contador.
     * Usa a query com índice GIN:
     *   temperatura > 80 OU presença da chave 'erro_codigo'
     * O trigger trg_DetectarAnomalias já deve ter marcado os contadores
     * como 'MANUTENCAO' no momento do INSERT — este endpoint mostra o histórico.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> listarAnomalias() {
        log.info("Listar anomalias JSONB (via índice GIN)");

        // Query nativa otimizada com índice GIN — definida no LeituraRepository
        List<Leitura> leituras = leituraRepository.findAnomaliasRecentes();

        // Contadores atualmente em manutenção
        List<Contador> emManutencao = contadorRepository.findByEstado("MANUTENCAO");

        log.info("Anomalias encontradas: {} leituras, {} contadores em manutenção",
                leituras.size(), emManutencao.size());

        return Map.of(
                "totalAnomalias", leituras.size(),
                "contadoresEmManutencao", emManutencao.size(),
                "leituras", leituras.stream().map(l -> Map.of(
                        "leituraId", l.getLeituraId(),
                        "contadorId", l.getContador().getContadorId(),
                        "dataHora", l.getDataHora().toString(),
                        "dadosAudit", l.getDadosAudit()
                )).collect(Collectors.toList()),
                "contadores", emManutencao.stream().map(c -> Map.of(
                        "contadorId", c.getContadorId(),
                        "numeroSerie", c.getNumeroSerie(),
                        "regiao", c.getRegiao() != null ? c.getRegiao() : "N/A",
                        "estado", c.getEstado()
                )).collect(Collectors.toList())
        );
    }

    /**
     * GET /api/admin/transactions
     * Histórico completo de transações para administração.
     */
    @Transactional(readOnly = true)
    public Map<String, Object> listarTransacoes() {
        log.info("Listar todas as transações");

        var transacoes = transacaoRepository.findAll();

        return Map.of(
                "total", transacoes.size(),
                "transacoes", transacoes.stream().map(t -> Map.of(
                        "transacaoId", t.getTransacaoId(),
                        "tipo", t.getTipoTransacao() != null ? t.getTipoTransacao() : "N/A",
                        "compradorId", t.getComprador().getUtilizadorId(),
                        "vendedorId", t.getVendedor().getUtilizadorId(),
                        "quantidade", t.getQuantidadeKwh(),
                        "valorTotal", t.getValorTotal(),
                        "dataTransacao", t.getDataTransacao().toString()
                )).collect(Collectors.toList())
        );
    }
}
