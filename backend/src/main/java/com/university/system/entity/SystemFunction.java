package com.university.system.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "functions")
@Getter
@NoArgsConstructor
public class SystemFunction {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false, unique = true, length = 100)
    private String name;

    private String description;

    @Column(name = "api_path")
    private String apiPath;

    @Column(name = "http_method", length = 10)
    private String httpMethod;
}
