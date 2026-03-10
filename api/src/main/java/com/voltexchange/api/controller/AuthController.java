package com.voltexchange.api.controller;

import com.voltexchange.api.dto.AuthResponse;
import com.voltexchange.api.dto.LoginRequest;
import com.voltexchange.api.dto.RegisterRequest;
import com.voltexchange.api.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@Slf4j
@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    /**
     * POST /api/auth/register
     * Regista novo utilizador. Público — sem autenticação necessária.
     *
     * Body: { "nome": "João", "email": "joao@test.com", "password": "senha123" }
     * Resposta: { "token": "...", "tipo": "Bearer", "email": "...", "nome": "..." }
     */
    @PostMapping("/register")
    public ResponseEntity<AuthResponse> register(@Valid @RequestBody RegisterRequest request) {
        log.debug("POST /api/auth/register - email: {}", request.getEmail());
        AuthResponse response = authService.register(request);
        return ResponseEntity.status(HttpStatus.CREATED).body(response);
    }

    /**
     * POST /api/auth/login
     * Autentica utilizador e devolve JWT. Público — sem autenticação necessária.
     *
     * Body: { "email": "joao@test.com", "password": "senha123" }
     * Resposta: { "token": "eyJ...", "tipo": "Bearer", "email": "...", "nome": "..." }
     */
    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest request) {
        log.debug("POST /api/auth/login - email: {}", request.getEmail());
        AuthResponse response = authService.login(request);
        return ResponseEntity.ok(response);
    }
}
