package com.university.system.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Builder;
import lombok.AllArgsConstructor;
import java.time.LocalDateTime;

@Entity
@Table(name = "system_logs")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class SystemLog {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "function_name", length = 100)
    private String functionName;

    @Column(name = "api_path", length = 255)
    private String apiPath;

    @Column(name = "http_method", length = 10)
    private String httpMethod;

    @Column(name = "request_body", columnDefinition = "JSON")
    private String requestBody;

    @Column(name = "response_status")
    private Integer responseStatus;

    @Enumerated(EnumType.STRING)
    @Column(name = "rbac_layer")
    private RbacLayer rbacLayer;

    @Column(name = "is_blocked")
    private Boolean isBlocked = false;

    @Column(name = "created_at")
    private LocalDateTime createdAt;

    @PrePersist
    protected void onCreate() { createdAt = LocalDateTime.now(); }

    public enum RbacLayer { LLM, API, BOTH }
}
