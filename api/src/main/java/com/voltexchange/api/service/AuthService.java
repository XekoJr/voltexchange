package com.voltexchange.api.service;

import com.voltexchange.api.dto.AuthResponse;
import com.voltexchange.api.dto.LoginRequest;
import com.voltexchange.api.dto.RegisterRequest;
import com.voltexchange.api.entity.Utilizador;
import com.voltexchange.api.repository.UtilizadorRepository;
import com.voltexchange.api.security.JwtTokenProvider;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;

@Slf4j
@Service
@RequiredArgsConstructor
public class AuthService {

    private final UtilizadorRepository utilizadorRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtTokenProvider jwtTokenProvider;

    /**
     * Regista um novo utilizador.
     * A password é sempre guardada com BCrypt (força 12) — nunca em texto limpo.
     */
    @Transactional
    public AuthResponse register(RegisterRequest request) {
        log.info("Tentativa de registo: {}", request.getEmail());

        // Verificar se o email já existe
        if (utilizadorRepository.existsByEmail(request.getEmail())) {
            throw new RuntimeException("Email já registado: " + request.getEmail());
        }

        // Criar utilizador — hash da password antes de persistir
        Utilizador utilizador = Utilizador.builder()
                .nome(request.getNome())
                .email(request.getEmail())
                .passwordHash(passwordEncoder.encode(request.getPassword()))
                .build();

        utilizadorRepository.save(utilizador);
        log.info("Utilizador registado com sucesso: {}", request.getEmail());

        // Gerar token JWT imediatamente após registo
        String token = jwtTokenProvider.generateToken(utilizador.getEmail());
        return new AuthResponse(token, utilizador.getEmail(), utilizador.getNome());
    }

    /**
     * Autentica um utilizador e retorna um JWT token.
     * Usa BCrypt.matches() para comparar a password com o hash guardado na BD.
     */
    @Transactional
    public AuthResponse login(LoginRequest request) {
        log.info("Tentativa de login: {}", request.getEmail());

        // Buscar utilizador pelo email — prepared statement automático via JPA
        Utilizador utilizador = utilizadorRepository.findByEmail(request.getEmail())
                .orElseThrow(() -> new RuntimeException("Credenciais inválidas"));

        // Verificar password com BCrypt
        if (!passwordEncoder.matches(request.getPassword(), utilizador.getPasswordHash())) {
            log.warn("Password incorreta para: {}", request.getEmail());
            throw new RuntimeException("Credenciais inválidas");
        }

        // Atualizar último acesso
        utilizador.setUltimoAcesso(LocalDateTime.now());
        utilizadorRepository.save(utilizador);

        String token = jwtTokenProvider.generateToken(utilizador.getEmail());
        log.info("Login bem-sucedido: {}", request.getEmail());
        return new AuthResponse(token, utilizador.getEmail(), utilizador.getNome());
    }
}
