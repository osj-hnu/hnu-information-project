# CampusRent Oracle 구축 SQL

2026-10-20 Physical ERD를 기준으로 만든 **Oracle 11g XE 호환 초안**입니다. 로컬 SQL*Plus 버전은 11.2.0.2.0으로 확인했습니다. 실제 DB 접속·생성·실행 검증은 아직 수행하지 않았습니다.

## 파일 및 실행 순서

| 파일 | 용도 |
| --- | --- |
| [01_schema.sql](01_schema.sql) | 26개 TBL_ 테이블, 185개 컬럼, 17개 SEQ_ 시퀀스, 162개 명명 제약조건(PK 포함, NOT NULL 제외), 33개 명시 인덱스 생성 |
| [02_verify_constraints.sql](02_verify_constraints.sql) | 메타데이터 확인, 정상 입력, 잘못된 입력 21건 거절 시험. 시험 데이터는 SAVEPOINT로 롤백 |
| [03_integrity_audit.sql](03_integrity_audit.sql) | 서비스가 보장해야 하는 교차 행·교차 테이블 규칙의 위반 조회. 데이터 변경 없음 |

**전용 빈 애플리케이션 스키마**에서 순서대로 실행합니다. DB 사용자 생성이나 SYS/SYSTEM 권한으로의 실행은 포함하지 않습니다. 필요한 권한·테이블스페이스 할당량은 DB 담당자가 준비합니다. 테이블·시퀀스 생성이 가능한 계정이어야 합니다.

SQL Developer에서는 연결을 선택하고 파일을 연 뒤 **스크립트 실행(F5)** 을 사용합니다. SQL*Plus에서는 비밀번호를 명령문에 넣지 않고 먼저 로그인한 뒤 다음 순서로 실행합니다. SQL*Plus는 01/02 실행 중 SQL 오류가 나면 종료하도록 설정되어 있습니다.

```sql
-- 접속 후 프로젝트 DB 시각을 KST로 운영하는 경우
ALTER SESSION SET TIME_ZONE = '+09:00';

-- 공백/한글이 포함된 경로는 큰따옴표로 감쌉니다.
@"C:/프로젝트경로/db/oracle/01_schema.sql"
@"C:/프로젝트경로/db/oracle/02_verify_constraints.sql"
@"C:/프로젝트경로/db/oracle/03_integrity_audit.sql"
```

SQL 파일은 UTF-8이며 SQL*Plus 사용 시 클라이언트 문자 인코딩도 맞춥니다. Oracle에 한글 업무 데이터를 저장할 수 있는 DB 문자셋인지 별도로 확인해야 합니다.

생성 SQL에는 DROP과 자동 재생성 로직이 없습니다. 재실행 시 기존 객체 충돌을 실패로 처리합니다. **Oracle DDL은 자동 커밋되므로 중간 오류가 나도 앞서 생성한 객체까지 롤백되는 것은 아닙니다.** 최초 적용 오류는 DB 담당자가 생성 상태를 확인해 해결합니다.

검증 SQL은 기존 업무 데이터를 삭제하지 않으며 시험 데이터 DML을 롤백합니다. 실행한 시퀀스 번호는 롤백되지 않으므로 번호에 공백이 생길 수 있습니다. 검증 SQL의 객체 수 검사는 해당 계정의 TBL_/SEQ_ 접두사 전체를 집계하므로 공용 계정 대신 전용 스키마에서 실행합니다. 03은 실제 서비스 데이터에 대한 진단용이며 제약조건이나 동시성 시험의 대체물이 아닙니다.

Spring Boot 자동 초기화 파일로 등록하지 않았습니다. 현재 앱의 하드코딩 목록을 DB로 연결하는 작업은 별도입니다.

## 접두사와 식별자 발급

- 테이블: 모든 ERD 테이블명 앞에 **TBL_**.
- 시퀀스: 단일 NUMBER(10) PK를 발급하는 테이블명 앞에 **SEQ_**.
- 복합키 테이블은 기존 FK·회차·구성품순번을 키로 사용하므로 별도 시퀀스 없음.
- PK_/FK_/UQ_/CK_/IX_는 제약·인덱스의 구분입니다. Oracle 11g의 30바이트 식별자 한도에 맞춰 영문 약어를 사용했습니다.
- IDENTITY·자동 ID 트리거는 사용하지 않습니다. INSERT 때 NEXTVAL을 명시합니다.
- 전체 17개 시퀀스는 START WITH 1, INCREMENT BY 1, MAXVALUE 9999999999, NOCYCLE, CACHE 20. 번호는 연속성·접수 순서를 보장하지 않습니다.
- 반납 회차·출고 구성품순번은 전역 시퀀스가 아닌 해당 출고 내부의 번호이며, 회차 할당에는 출고/신청 잠금이 필요합니다.

```sql
INSERT INTO TBL_USE_PURPOSE (
    PURPOSE_ID, PURPOSE_CODE, PURPOSE_NAME, DESCRIPTION_TEXT
) VALUES (
    SEQ_USE_PURPOSE.NEXTVAL, 'TEAM_MEETING', '팀 회의',
    '팀 활동과 참여 인원에 적합한 공간 탐색'
);
```

시퀀스가 있는 테이블:

APP_USER, USE_PURPOSE, EQUIPMENT_TYPE, EQUIPMENT_MODEL, SPEC_ITEM, EQUIPMENT, EQUIPMENT_COMPONENT, PURPOSE_KEYWORD, FACILITY, FACILITY_BLOCK, SELECTION_ITEM, RENT_REQUEST, REQUEST_ITEM, REQUEST_STATUS_LOG, EQUIPMENT_CHECKOUT, FACILITY_USAGE, EQUIPMENT_CHECK_LOG.

예: `TBL_REQUEST_ITEM.REQUEST_ITEM_ID ← SEQ_REQUEST_ITEM.NEXTVAL`.

## ERD와 비교한 변경 범위

컬럼은 추가·삭제하지 않았으며 자료형·NULL 허용 여부와 총 185개 컬럼을 유지했습니다. 테이블명 접두사와 다음 제약·기본값·인덱스·컬럼 주석을 추가했습니다.

- 자원은 E=장비/F=시설 중 정확히 하나만 연결. 시설 신청은 인원·목적 필수.
- 시설에는 장비 전용 반납 상태를 허용하지 않음.
- 신청 항목별 출고/실제 시설 이용은 1개. REQUEST_ITEM의 ID+유형 조합을 복합 FK로 참조해 반대 유형에 연결되지 않게 함.
- 반납 구성품은 동일 출고의 검수 회차와 구성품을 각각 복합 FK로 참조.
- 신청·선택·차단 기간, 시설 실제 종료 시각/처리자 쌍, 요일·시각 형식, 양수/0 이상 수량·버전 검사.
- 이메일·업무 코드·신청 내 항목번호 중복 금지.
- 거절·보류·손상 설명과 대체 지정 사유 등 필수 사유의 공백 입력 방지.
- 방향성 있는 대체 장비 관계에서 자기 자신 지정 금지.
- 이력을 지우는 ON DELETE CASCADE는 사용하지 않음.
- 정상 출고는 실제 출고 시각 필수. 사후 등록은 불명확한 실제 시각을 NULL로 유지 가능.

ROW_VERSION은 기본 0이며 서버가 성공 시 증가시켜야 합니다. CREATED_AT/REQUESTED_AT/ADDED_AT/REGISTERED_AT 등 생성 시각은 LOCALTIMESTAMP 기본값을 사용합니다. UPDATED_AT도 최초 기본값만 제공하며 수정 때는 서버가 다시 기록해야 합니다.

Y/N 기본값은 사용·허용·필수반환=Y, 본체=N, 가상 데이터=Y입니다. 실제 자원 등록 시 IS_DEMO_YN='N'을 명시합니다. 운영상태는 NORMAL, 가입 역할은 STUDENT, 신청 상태는 pending입니다. 계정 PASSWORD는 기존 컬럼명을 유지하되 실제 서버용 비밀번호 해시만 저장합니다.

## 화면 ↔ DB 코드 계약

아래 값은 기존 화면과 연결하기 위해 이 SQL에서 채택한 **구현 제안값**입니다. 기존 확정 코드표가 있다면 CHECK와 서버 변환표를 함께 수정해야 합니다.

| 항목 | 저장값 |
| --- | --- |
| ITEM_KIND | E=장비, F=시설 |
| ROLE_CODE | STUDENT, ADMIN |
| STATUS_CODE / FROM_STATUS / TO_STATUS(신청) | 원본과 같은 pending, approved, collected, return_requested, return_held, returned, rejected, cancelled |
| OPERATING_STATUS / 점검 FROM_STATUS·TO_STATUS | NORMAL, INSPECTION, STOPPED |
| ORIGIN_CODE | DIRECT=직접 조회, PURPOSE=목적 추천, ALT_TIME=다른 일정, ALT_ASSET=대체 자원 |
| ALTERNATIVE_KIND | EQUIPMENT_TIME, EQUIPMENT_SWAP, FACILITY_TIME, FACILITY_SWAP |
| SOURCE_CODE(출고) | NORMAL ← registered-demo-checkout, RETRO ← admin-retrospective |
| OUT_CONDITION / RETURN_CONDITION | NORMAL, DAMAGED |
| OUTCOME_CODE | HOLD ← return_held, COMPLETE ← returned |
| NEED_LEVEL | REQUIRED, OPTIONAL |
| VERIFY_STATUS | VERIFIED, UNKNOWN |
| MATCH_MODE | EXACT, CONTAINS, REGEX |
| EFFECT_CODE | INCLUDE, EXCLUDE |
| ACTION_CODE(점검) | REQUIRED, RETURN_INSPECTION, COMPLETED |
| WEEKDAY_NO | ISO 요일: 월=1, …, 일=7. 운영시간 행 없음=휴무 |

출고 원본값 registered-demo-checkout은 23자이므로 VARCHAR2(20)에 직접 저장하지 않습니다. NORMAL로 변환해 ERD 자료형을 유지했습니다. 원본 Date.getDay()의 일=0 기준을 쓰는 프런트에서는 ISO 요일로 변환합니다. REGEX 문법 유효성·활동 인식·인원 추출과 추천 우선순위 적용은 서버에서 구현합니다.

RETURN_COMPONENT에는 **이번 회차에 실제 확인한 품목만** 저장합니다. 행 없음=이번에 확인하지 않음, 수량 0인 행=이번에 0개 반환을 확인함입니다. 누적 수량은 회차별 RETURNED_QTY 합계이며 현재 마스터 구성품으로 과거 출고 기준을 대체하면 안 됩니다. 점검·손상 여부도 이전 이력과 출고 당시 상태를 포함하여 판단합니다.

## CHECK/FK만으로 보장할 수 없는 업무 규칙

다음 항목은 이 DDL이 자동 보장한다고 간주하면 안 됩니다. Spring 서비스 트랜잭션으로 구현해야 합니다.

1. **동시 승인 중복 방지:** 장비/시설 마스터 행을 FOR UPDATE로 잠근 뒤 최신 운영 조건·겹치는 확보 내역 재조회. pending은 확보하지 않고 원본 기준 approved/collected/return_requested/return_held/returned의 예정 기간은 유지. 다른 신청의 ROW_VERSION만 비교하면 부족합니다.
2. **상태 전이와 이력 원자성:** 현재 상태·역할·소유권을 검사하고 신청 변경/이력/검수/점검 상태를 함께 저장. 시설별 불법 이력 코드, 과거 상태와 맞지 않는 전환은 서버에서 차단합니다. 같은 상태를 유지하는 보류 재확인·점검 이벤트는 허용합니다.
3. **누적 초과 반환·회차 충돌:** 출고/신청 잠금 후 누적 합계 확인, 회차 배정, 반환 행 저장. 단일 RETURNED_QTY의 음수는 CHECK로 막지만 여러 회차 합계의 초과는 서버 검증 대상입니다. 03의 진단 쿼리도 이를 탐지할 뿐 예방하지 않습니다.
4. **모델/사양의 품목 일치, 시설별 허용 목적·수용 인원·운영 시간·차단 확인.** 동일 시설 목적 일치는 복합 FK로 강제하지 않았으므로 과거 신청의 목적이 마스터 운영 변경으로 삭제될 때도 신청 이력이 보존됩니다. 현재 등록 가능 여부는 신청·승인 시 서버에서 재검사합니다.
5. **고정 세트 출고 검수:** 구성품 행이 1개 이상인지, 본체가 있는지, 정상 출고 수량이 기준과 같은지 검사. 사후 출고 기준은 실제 과거 전달 내용을 보존하므로 단순 DELIVERED_QTY=REQUIRED_QTY CHECK를 일괄 적용하지 않았습니다.
6. **출고·시설 이용 가능 상태, 미반납·미종료 제한, 전량 반환과 장비 점검 해제의 구분.**
7. **관리자 전용 FK의 역할:** REGISTERED_BY 등의 FK는 사용자 존재만 보장합니다. ADMIN 여부와 일반 가입에서 관리자 선택 금지는 서버 인증으로 검사합니다.
8. **대안 선택 유지 조건:** 다른 시간 선택은 같은 자원·이용 길이 유지, 대체 자원 선택은 같은 기간 유지 등. REQUEST_ALTERNATIVE와 최종 REQUEST_ITEM을 함께 검사합니다.
9. **저장 후 버전 증가·스냅샷 변경 금지:** 운영 변경에 따른 부모 버전 증가, 출고 구성품 변경 금지, 신청별 처리자·시각 기록.
10. **API 정수·공백 입력:** NUMBER(p)는 저장 시 소수 입력이 반올림될 수 있으므로 정수 여부는 API에서도 검사합니다.

시설 운영/차단 변경·장비 점검 변경도 승인과 같은 자원 잠금 규약을 따라야 합니다. 여러 자원 잠금은 일관된 순서를 사용합니다.

03의 허용 목적 진단은 **최신 마스터**와의 차이도 출력하므로 과거 신청이 정책 변경 후 조회된 경우 담당자가 구분해야 합니다. 차단/운영 변경을 자동으로 과거 오류라고 취급하거나 예약을 자동 취소하지 않습니다.

## 아직 결정하지 않은 확장

[Physical 검토 보고서](../../docs/erd/physical-model-review.md)의 과거 신청명·사양 스냅샷, 선택 목록 서버 복구·버전, 분할 운영 시간, 알림·취소 대기 등은 이번 DDL에 임의로 추가하지 않았습니다. 출고 구성품 보존은 기존 ERD 구조 그대로 구현했습니다.

## 이번 검증 범위

정적 검증 결과: 26개 테이블·185개 컬럼·17개 시퀀스·162개 명명 제약조건·44개 FK·33개 명시 인덱스를 확인했습니다. PDF에서 추출한 컬럼명·자료형·NULL 허용 여부의 전체 구성과 생성 SQL이 일치했고, 객체명 30바이트 한도·중복 이름·FK 자식 컬럼·부모 PK/UQ·생성 순서 검사도 통과했습니다.

실제 Oracle 연결 정보가 제공되지 않았으므로 01/02/03을 DB에 실행한 결과는 아직 없습니다. 02는 실행 시 21건의 예상 거절과 정상 저장·누적 조회를 검증하도록 준비한 파일이며, 이미 통과한 시험 결과를 의미하지 않습니다.
