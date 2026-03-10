package com.voltexchange.api.dto;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class AuthResponse {

    private String token;
    private String tipo = "Bearer";
    private String email;
    private String nome;

    public AuthResponse(String token, String email, String nome) {
        this.token = token;
        this.email = email;
        this.nome = nome;
    }
}
