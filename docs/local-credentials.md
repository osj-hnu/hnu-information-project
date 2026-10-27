# DB 계정·API 키 관리

실제 값은 환경변수 또는 Git에서 제외한 로컬 설정에만 둡니다. 공유하는 예시 파일에는 변수명과 빈 값만 작성합니다.

## 현재 준비된 설정

- `.env.example`: 필요한 환경변수 이름. Spring Boot가 `.env`를 자동으로 읽지는 않습니다.
- `config/application-secrets.properties.example`: 환경변수를 참조하는 설정 예시.
- `config/application-secrets.properties`: Git 제외 대상. 프로젝트 루트에서 실행하면 Spring Boot가 선택적으로 읽습니다. 파일이 없어도 현재 홈 화면은 실행됩니다.
- `.env` 계열, 로컬 DB SQL, `secrets/`, 개인키·인증서 저장소·Oracle wallet도 Git에서 제외합니다.

예시 설정을 로컬 파일로 복사하고, 애플리케이션을 실행할 프로세스에 `DB_URL`, `DB_USERNAME`, `DB_PASSWORD`, 향후 `EXTERNAL_API_KEY`를 설정합니다. 예시의 datasource 설정은 JDBC 연동 시 활성화합니다. 현재 DB/API 연결 기능을 추가한 것은 아닙니다.

DB 비밀번호를 SQL*Plus 명령행에 넣지 말고 로그인 프롬프트에서 입력합니다. 터미널 명령·스크린샷·로그에 실제 값을 출력하지 않습니다. 운영 환경에서는 배포 서비스의 비밀값 설정을 사용합니다.

## API 연동 시 적용할 기준

비밀 API 키는 Spring 서버에서 읽고 외부 API를 호출합니다. HTML·JavaScript·템플릿의 모델 값·브라우저 저장소·응답 JSON에 넣지 않습니다. 브라우저는 키를 포함하지 않은 우리 서버의 API를 호출하도록 구현합니다. 공개 사용을 전제로 발급된 키는 제공 업체의 사용 조건에 맞게 별도로 판단합니다.

공유하는 `application.properties`, SQL, README, `.env.example`, VS Code 설정에는 실제 값을 넣지 않습니다. 특히 공유 VS Code 설정에 DB 비밀번호나 키를 직접 작성하지 않습니다.

## 커밋 전 확인

```text
git check-ignore -v config/application-secrets.properties .env
git diff --cached --name-only
```

`.gitignore`는 이미 추적 중인 파일이나 `git add -f`로 강제 추가한 파일의 공개를 막지 못합니다. 추적되었던 파일은 필요 시 `git rm --cached <파일>`로 추적을 해제하고, 비밀값이 원격에 올라갔다면 파일 삭제와 별도로 해당 비밀번호·키를 교체합니다. 커밋할 때는 예시 파일에도 실제 값이 없는지 확인합니다.
