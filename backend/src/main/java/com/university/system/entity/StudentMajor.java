package com.university.system.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Entity
@Table(name = "student_majors",
    uniqueConstraints = @UniqueConstraint(columnNames = {"student_id", "department_id", "major_type"}))
@Getter
@NoArgsConstructor
public class StudentMajor {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "department_id", nullable = false)
    private Department department;

    @Enumerated(EnumType.STRING)
    @Column(name = "major_type", nullable = false)
    private MajorType majorType;

    @Column(name = "declared_at")
    private LocalDate declaredAt;

    public enum MajorType {
        MAIN, DOUBLE, MINOR
    }
}
