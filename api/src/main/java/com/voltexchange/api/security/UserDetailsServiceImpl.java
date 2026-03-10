package com.voltexchange.api.security;

import com.voltexchange.api.repository.UtilizadorRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.userdetails.User;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.core.userdetails.UsernameNotFoundException;
import org.springframework.stereotype.Service;

import java.util.Collections;

@Service
@RequiredArgsConstructor
public class UserDetailsServiceImpl implements UserDetailsService {

    private final UtilizadorRepository utilizadorRepository;

    // Carrega o utilizador pelo email — chamado pelo Spring Security em cada request
    @Override
    public UserDetails loadUserByUsername(String email) throws UsernameNotFoundException {
        var utilizador = utilizadorRepository.findByEmail(email)
                .orElseThrow(() -> new UsernameNotFoundException(
                        "Utilizador não encontrado com email: " + email
                ));

        // Sem roles por agora — apenas autenticação básica
        return new User(
                utilizador.getEmail(),
                utilizador.getPasswordHash(),
                Collections.emptyList()
        );
    }
}
