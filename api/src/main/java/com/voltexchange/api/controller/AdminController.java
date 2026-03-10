package com.voltexchange.api.controller;

import com.voltexchange.api.service.AdminService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.Map;

@Slf4j
@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final AdminService adminService;

    /**
     * GET /api/admin/anomalies
     * Lista contadores com anomalias detectadas via JSONB.
     * Usa a query nativa com índice GIN:
     *   temperatura > 80 OU presença da chave 'erro_codigo'
     * Este endpoint é avaliado no Checkpoint 2.
     * Requer: Authorization: Bearer <token>
     *
     * Resposta: {
     *   "totalAnomalias": 5,
     *   "contadoresEmManutencao": 3,
     *   "leituras": [...],
     *   "contadores": [...]
     * }
     */
    @GetMapping("/anomalies")
    public ResponseEntity<Map<String, Object>> listarAnomalias() {
        log.info("GET /api/admin/anomalies");
        return ResponseEntity.ok(adminService.listarAnomalias());
    }

    /**
     * GET /api/admin/transactions
     * Histórico completo de transações (diretas e matched).
     * Requer: Authorization: Bearer <token>
     */
    @GetMapping("/transactions")
    public ResponseEntity<Map<String, Object>> listarTransacoes() {
        log.info("GET /api/admin/transactions");
        return ResponseEntity.ok(adminService.listarTransacoes());
    }
}
