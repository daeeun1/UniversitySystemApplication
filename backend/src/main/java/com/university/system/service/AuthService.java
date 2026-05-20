package com.university.system.service;

import com.university.system.dto.LoginRequest;
import com.university.system.dto.LoginResponse;
import com.university.system.entity.User;
import com.university.system.repository.UserRepository;
import com.university.system.security.JwtUtil;
import lombok.RequiredArgsConstructor;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtUtil jwtUtil;

    public LoginResponse login(LoginRequest request) {
        User user = userRepository.findByUserNumber(request.getUserNumber())
            .orElseThrow(() -> new IllegalArgumentException("존재하지 않는 학번/교번입니다."));

        if (!user.getIsActive()) {
            throw new IllegalStateException("비활성화된 계정입니다.");
        }

        if (!passwordEncoder.matches(request.getPassword(), user.getPasswordHash())) {
            throw new IllegalArgumentException("비밀번호가 올바르지 않습니다.");
        }

        String token = jwtUtil.generateToken(user.getUserNumber(), user.getRole().getName());
        return new LoginResponse(token, user.getUserNumber(), user.getName(), user.getRole().getName());
    }
}
