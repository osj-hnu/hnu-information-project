# Figma Make → Spring Boot 화면 구현

원본: https://www.figma.com/make/YSXPP4xr2PpdF9bjS9U2Xh/Implement-CampusRent-Home-Screen--Copy-

## 구현 범위

- 홈의 문구·색상·레이아웃·SVG 아이콘을 HTML/CSS/JavaScript + Thymeleaf로 이식했습니다.
- 추천 키워드 클릭, 입력값 URL 보존, 목적 입력 전달, 장비·시설 목록 이동 및 서버 검색을 지원합니다.
- 장비·시설 탐색 화면은 원본 가상 데이터 일부를 사용한 연결 화면입니다. 원본 상세 대여 화면 전체를 이식한 것은 아닙니다.
- 목적별 추천 알고리즘, 선택 목록, 실제 로그인·신청·승인·출고·반납, Oracle 연결은 미구현입니다. 화면에서 미구현 기능을 완료된 것처럼 표시하지 않습니다.
- Make 파일은 MCP `create_session` 및 `get_screenshot`을 지원하지 않아 소스 기준으로 구현했습니다. 원본과 브라우저 화면의 시각 비교는 별도 확인이 필요합니다.

## 로컬 실행

JDK 17 이상 및 Maven 3.6.3 이상이 필요합니다. 기존 Java 8로는 실행할 수 없습니다.

```powershell
mvn test
mvn spring-boot:run
```

http://localhost:8080 에서 확인합니다. 패키징은 `mvn package`, 실행은 `java -jar target/campusrent-0.1.0-SNAPSHOT.jar`입니다.

작업 중 다운로드한 `.tools`가 있으면 다음으로 로컬 도구를 사용합니다. 시스템 Java 설정은 바꾸지 않습니다.

```powershell
$env:JAVA_HOME = (Get-ChildItem .tools -Directory -Filter 'jdk*' | Select-Object -First 1).FullName
& .\.tools\apache-maven-3.9.9\bin\mvn.cmd '-Dmaven.repo.local=.tools/m2' test
& .\.tools\apache-maven-3.9.9\bin\mvn.cmd '-Dmaven.repo.local=.tools/m2' spring-boot:run
```

## 후속 연동

`CatalogService`의 가상 목록을 팀에서 확정한 MyBatis 또는 JDBC 조회로 대체합니다. DB 접속 정보는 환경변수로 관리합니다. 이번 작업은 화면 이식 단계이며 운영 가능한 예약 시스템 전체 완성이 아닙니다.

## 검증 결과

- `mvn test`: 렌더링·정적 파일·장비/시설 검색·빈 결과·입력 이스케이프 테스트 3개 통과.
- Chrome 데스크톱 1440px 화면과 모바일 에뮬레이션 390px 화면 캡처 확인.
- 모바일 `innerWidth=390`, 문서 너비 `390`, 로딩 실패 이미지 `0` 확인.
- 키워드 클릭 후 입력값·선택 표시·주소의 activity 값·목적별 대여 링크의 activity 값 일치 확인.
- 원본 Make 스크린샷 API 미지원으로 원본 화면과의 이미지 대조는 미수행. 폰트는 설치된 로컬 폰트에 따라 차이가 있을 수 있음.
