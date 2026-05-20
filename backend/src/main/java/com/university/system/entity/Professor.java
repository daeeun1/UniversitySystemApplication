package com.university.system.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;

@Entity
@Table(name = "professors")
@Getter
@NoArgsConstructor
public class Professor {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id", nullable = false)
    private Department department;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private ProfessorRank rank = ProfessorRank.ASSISTANT;

    @Column(length = 100)
    private String office;

    public enum ProfessorRank {
        ASSISTANT, ASSOCIATE, FULL, EMERITUS
    }
}
