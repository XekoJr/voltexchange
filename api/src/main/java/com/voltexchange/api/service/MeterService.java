package com.voltexchange.api.service;

import com.voltexchange.api.dto.ReadingRequest;
import com.voltexchange.api.entity.Contador;
import com.voltexchange.api.entity.Leitura;
import com.voltexchange.api.repository.ContadorRepository;
import com.voltexchange.api.repository.LeituraRepository;
import com.voltexchange.api.repository.UtilizadorRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;

@Slf4j
@Service
@RequiredArgsConstructor
public class MeterService {

    private final LeituraRepository leituraRepository;
    private final ContadorRepository contadorRepository;
    private final UtilizadorRepository utilizadorRepository;

    /**
     * Regista uma nova leitura de contador.
     * O campo DadosAudit é gravado como JSONB — o trigger trg_DetectarAnomalias
     * na BD verifica automaticamente se há anomalias e muda o estado do contador
     * para 'MANUTENCAO' se temperatura > 80 ou se existir a chave 'erro_codigo'.
     */
    @Transactional
    public Leitura registarLeitura(Integer contadorId, ReadingRequest request, String emailUtilizador) {
        log.info("Registar leitura para contador: {}", contadorId);

        // Validar que o contador existe e pertence ao utilizador autenticado
        Contador contador = contadorRepository.findById(contadorId)
                .orElseThrow(() -> new RuntimeException(
                        "Contador não encontrado: " + contadorId));

        if (!contador.getUtilizador().getEmail().equals(emailUtilizador)) {
            throw new RuntimeException("Sem permissão para este contador");
        }

        // Construir leitura com dataHora para a PK composta (particionamento)
        Leitura leitura = Leitura.builder()
                .dataHora(LocalDateTime.now())
                .contador(contador)
                .kwhLeitura(request.getKwhLeitura())
                .dadosAudit(request.getDadosAudit())
                .build();

        Leitura saved = leituraRepository.save(leitura);
        log.info("Leitura registada no contador: {}", contadorId);
        return saved;
    }

    /**
     * Lista leituras de um contador num intervalo de datas.
     * Aproveita o particionamento por DataHora — só lê as partições relevantes.
     */
    @Transactional(readOnly = true)
    public List<Leitura> listarLeiturasPorPeriodo(Integer contadorId,
                                                   LocalDateTime inicio,
                                                   LocalDateTime fim,
                                                   String emailUtilizador) {
        // Validar que o contador pertence ao utilizador autenticado
        Contador contador = contadorRepository.findById(contadorId)
                .orElseThrow(() -> new RuntimeException("Contador não encontrado: " + contadorId));

        if (!contador.getUtilizador().getEmail().equals(emailUtilizador)) {
            throw new RuntimeException("Sem permissão para este contador");
        }

        return leituraRepository.findByContadorAndPeriodo(contadorId, inicio, fim);
    }

    /**
     * Lista todos os contadores do utilizador autenticado.
     */
    @Transactional(readOnly = true)
    public List<Contador> listarContadoresDoUtilizador(String emailUtilizador) {
        var utilizador = utilizadorRepository.findByEmail(emailUtilizador)
                .orElseThrow(() -> new RuntimeException("Utilizador não encontrado"));

        return contadorRepository.findByUtilizadorUtilizadorId(utilizador.getUtilizadorId());
    }
}
