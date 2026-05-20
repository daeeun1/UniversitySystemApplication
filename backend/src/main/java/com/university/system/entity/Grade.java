package com.university.system.entity;

import jakarta.persistence.*;
import lombok.Getter;
import lombok.NoArgsConstructor;
import lombok.Builder;
import lombok.AllArgsConstructor;
import java.math.BigDecimal;
import java.time.LocalDateTime;

@Entity
@Table(name = "grades")
@Getter
@NoArgsConstructor
@AllArgsConstructor
@Builder
public class Grade {

    @Id @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    @OneToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "enrollment_id", nullable = false, unique = true)
    private Enrollment enrollment;

    @Column(precision = 5, scale = 2)
    private BigDecimal score;

    @Enumerated(EnumType.STRING)
    private GradeType grade;

    @Column(name = "graded_at")
    private LocalDateTime gradedAt;

    @Column(name = "updated_at")
    private LocalDateTime updatedAt;

    @PrePersist
    protected void onCreate() {
        gradedAt = LocalDateTime.now();
        updatedAt = LocalDateTime.now();
    }

    @PreUpdate
    protected void onUpdate() {
        updatedAt = LocalDateTime.now();
    }

    public enum GradeType {
        A_PLUS("A+"), A_ZERO("A0"), B_PLUS("B+"), B_ZERO("B0"),
        C_PLUS("C+"), C_ZERO("C0"), D_PLUS("D+"), D_ZERO("D0"),
        F("F"), P("P"), NP("NP");

        private final String label;
        GradeType(String label) { this.label = label; }
        public String getLabel() { return label; }

        public static GradeType fromLabel(String label) {
            for (GradeType g : values()) {
                if (g.label.equals(label)) return g;
            }
            throw new IllegalArgumentException("Invalid grade: " + label);
        }
    }
}
