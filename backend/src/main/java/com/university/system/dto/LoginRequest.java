package com.university.system.dto;

import jakarta.validation.constraints.NotBlank;
import lombok.Getter;

@Getter
public class LoginRequest {
    @NotBlank private String userNumber;
    @NotBlank private String password;
}
