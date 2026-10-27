package kr.ac.hnu.campusrent.catalog;

import org.springframework.stereotype.Service;
import java.util.List;

/** Figma Make의 가상 데이터. 실제 재고·예약 가능 여부를 나타내지 않는다. */
@Service
public class CatalogService {
    public record Resource(String id, String kind, String name, String description, String icon) {}
    private final List<Resource> resources = List.of(
        new Resource("cam01", "장비", "이동형 디지털카메라 고정 세트 A", "DEMO-CAM100 · 영상 4K / 30fps · 기본 렌즈 24–70mm", "ff97a.svg"),
        new Resource("cam02", "장비", "이동형 디지털카메라 고정 세트 B", "DEMO-CAM200 · 영상 1080p / 60fps · 기본 렌즈 18–55mm", "ff97a.svg"),
        new Resource("proj01", "장비", "이동형 빔프로젝터 고정 세트 A", "DEMO-PJ100 · 해상도 1920×1080 · 입력 HDMI", "1eae3.svg"),
        new Resource("proj02", "장비", "이동형 빔프로젝터 고정 세트 B", "DEMO-PJ200 · 해상도 1280×800 · 입력 HDMI", "1eae3.svg"),
        new Resource("mic01", "장비", "무선 마이크 고정 세트 A", "DEMO-MIC100 · 녹음 1채널 · 출력 3.5mm", "054e2.svg"),
        new Resource("mic02", "장비", "무선 마이크 고정 세트 B", "DEMO-MIC200 · 녹음 2채널 · 출력 3.5mm", "054e2.svg"),
        new Resource("room01", "시설", "시연 회의실 A", "수용 4명 · 테이블 · 화이트보드 · 가상 캠퍼스 A동 201호", "b46a5.svg"),
        new Resource("room02", "시설", "시연 회의실 B", "수용 8명 · 고정 전자칠판 · 가상 캠퍼스 A동 202호", "b46a5.svg"),
        new Resource("study01", "시설", "시연 스터디룸 B", "수용 6명 · 고정 PC · 가상 캠퍼스 B동 101호", "b46a5.svg"),
        new Resource("studio01", "시설", "시연 촬영실 A", "수용 4명 · 고정 조명 · 가상 캠퍼스 C동 101호", "b46a5.svg"),
        new Resource("studio02", "시설", "시연 촬영실 B", "수용 6명 · 고정 조명 · 방음 설비 · 가상 캠퍼스 C동 102호", "b46a5.svg")
    );

    public List<Resource> search(String kind, String query) {
        String keyword = query.strip().toLowerCase(java.util.Locale.ROOT);
        return resources.stream().filter(r -> r.kind().equals(kind))
            .filter(r -> (r.name() + " " + r.description()).toLowerCase(java.util.Locale.ROOT).contains(keyword)).toList();
    }
}
