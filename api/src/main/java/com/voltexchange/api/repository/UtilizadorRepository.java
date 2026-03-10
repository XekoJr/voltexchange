// ============================================================
// UtilizadorRepository.java
// ============================================================
package com.voltexchange.api.repository;

import com.voltexchange.api.entity.Utilizador;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.Optional;

@Repository
public interface UtilizadorRepository extends JpaRepository<Utilizador, Integer> {

    // Usado na autenticação — prepared statement automático via JPA
    Optional<Utilizador> findByEmail(String email);

    // Verificar se email já existe (registo)
    boolean existsByEmail(String email);
}
