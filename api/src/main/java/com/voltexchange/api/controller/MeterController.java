package com.voltexchange.api.controller;

import com.voltexchange.api.dto.ReadingRequest;
import com.voltexchange.api.entity.Contador;
import com.voltexchange.api.entity.Leitura;
import com.voltexchange.api.service.MeterService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.format.annotation.DateTimeFormat;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDateTime;
import java.util.List;
import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/meters")
@RequiredArgsConstructor
public class MeterController {

    private final MeterService meterService;

    /**
     * POST /api/meters/{contadorId}/readings
     * Recebe payload JSON e grava na tabela Leituras com DadosAudit em JSONB.
     * O trigger trg_DetectarAnomalias é disparado automaticamente na BD após o INSERT.
     * Requer: Authorization: Bearer <token>
     *
     * Body: {
     *   "kwhLeitura": 45.230,
     *   "dadosAudit": { "temperatura": 45, "voltagem": 230, "erro_codigo": null }
     * }
     */
    @PostMapping("/{contadorId}/readings")
    public ResponseEntity<Map<String, Object>> registarLeitura(
            @PathVariable Integer contadorId,
            @Valid @RequestBody ReadingRequest request,
            @AuthenticationPrincipal UserDetails userDetails) {

        log.debug("POST /api/meters/{}/readings", contadorId);

        Leitura leitura = meterService.registarLeitura(contadorId, request, userDetails.getUsername());

        return ResponseEntity.status(HttpStatus.CREATED).body(Map.of(
                "mensagem", "Leitura registada com sucesso",
                "leituraId", leitura.getLeituraId(),
                "dataHora", leitura.getDataHora().toString(),
                "contadorId", contadorId
        ));
    }

    /**
     * GET /api/meters/{id}/readings?inicio=...&fim=...
     * Lista leituras de um contador num período.
     * Aproveita o particionamento por DataHora — só acede às partições do período.
     * Requer: Authorization: Bearer <token>
     */
    @GetMapping("/{id}/readings")
    public ResponseEntity<List<Leitura>> listarLeituras(
            @PathVariable Integer id,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime inicio,
            @RequestParam @DateTimeFormat(iso = DateTimeFormat.ISO.DATE_TIME) LocalDateTime fim,
            @AuthenticationPrincipal UserDetails userDetails) {

        log.debug("GET /api/meters/{}/readings", id);
        List<Leitura> leituras = meterService.listarLeiturasPorPeriodo(
                id, inicio, fim, userDetails.getUsername());
        return ResponseEntity.ok(leituras);
    }

    /**
     * GET /api/meters
     * Lista os contadores do utilizador autenticado.
     * Requer: Authorization: Bearer <token>
     */
    @GetMapping
    public ResponseEntity<List<Contador>> listarContadores(
            @AuthenticationPrincipal UserDetails userDetails) {

        log.debug("GET /api/meters - utilizador: {}", userDetails.getUsername());
        List<Contador> contadores = meterService.listarContadoresDoUtilizador(
                userDetails.getUsername());
        return ResponseEntity.ok(contadores);
    }
}
