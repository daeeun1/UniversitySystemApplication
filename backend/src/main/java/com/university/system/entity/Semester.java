package com.university.system.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import java.time.LocalDate;

@Entity
@Table(name = "semesters", uniqueConstraints = @UniqueConstraint(columnNames = {"year", "term"}))
@Getter
@NoArgsConstructor
public class Semester {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Integer id;

    @Column(nullable = false)
    private Integer year;

    @Column(nullable = false)
    private Integer term;

    @Column(name = "start_date", nullable = false)
    private LocalDate startDate;

    @Column(name = "end_date", nullable = false)
    private LocalDate endDate;

    @Column(name = "enroll_start")
    private LocalDate enrollStart;

    @Column(name = "enroll_end")
    private LocalDate enrollEnd;

    @Column(name = "is_current")
    private Boolean isCurrent = false;

    public String getLabel() {
        return year + "-" + term;
    }
}
