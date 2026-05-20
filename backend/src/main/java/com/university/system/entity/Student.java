package com.university.system.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.util.ArrayList;
import java.util.List;

@Entity
@Table(name = "students")
@Getter
@NoArgsConstructor
public class Student {

    @Id
    @Column(name = "user_id")
    private Long userId;

    @OneToOne(fetch = FetchType.LAZY)
    @MapsId
    @JoinColumn(name = "user_id")
    private User user;

    @Column(name = "admission_year", nullable = false)
    private Integer admissionYear;

    @Column(nullable = false)
    private Integer grade = 1;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private StudentStatus status = StudentStatus.ENROLLED;

    @Column(name = "total_credits")
    private Integer totalCredits = 0;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "main_dept_id", nullable = false)
    private Department mainDepartment;

    @OneToMany(mappedBy = "student", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<StudentMajor> majors = new ArrayList<>();

    public enum StudentStatus {
        ENROLLED, ON_LEAVE, GRADUATED, EXPELLED
    }
}
