# CampusRent Physical ERD ↔ 화면·기능 매핑 검토

검토일: 2026-10-27 / 상태: DB 구축 전 검토안

후속 산출물: [TBL_/SEQ_ 규칙을 반영한 Oracle 생성·검증 SQL](../../db/oracle/README.md). 기존 26개 테이블·185개 컬럼을 유지하고 제약조건·기본값·인덱스를 반영했습니다. 아래 미결정 확장 항목을 모두 추가한 것은 아니며 실제 DB 적용은 별도입니다.

## 1. 결론과 검토 범위

현재 ERD는 필수 업무의 주요 데이터를 담고 있습니다. **26개 테이블·185개 컬럼**을 PDF Physical 페이지에서 확인했습니다. 테이블을 대폭 늘리기보다, 상태 코드·무결성 제약·동시 처리·과거 정보 보존 기준을 확정하는 것이 우선입니다.

다만 **PDF만으로 실제 DB 생성 준비가 끝났다고 판정할 수는 없습니다.** PK/FK와 NULL 여부는 보이지만, UQ·CHECK·DEFAULT·인덱스·ID 생성 방식과 FK의 정확한 컬럼 조합은 Erwin 원본 또는 생성 DDL로 추가 확인해야 합니다. 아래에서 ‘필요’라고 표시한 제약은 PDF에 안 보인다는 의미이며, 원본 모델에 없다고 단정하지 않습니다.

검토 자료:

- [`[New-Era] CampusRent_ERD_20261020.pdf`](./%5BNew-Era%5D%20CampusRent_ERD_20261020.pdf): 1쪽 Logical, **2쪽 Physical**. 텍스트 추출과 관계도 이미지 확인.
- [프로젝트 기준 문서](../New-Era_PROJECT.md): F01~F29, 6장 업무 규칙, 7.5 ERD 기준, 성공 기준.
- `docs/usecase/[New-Era] 요구사항 분석_USE_CASE_ 20261020.docx`: 내부에 포함된 유스케이스 이미지 확인.
- [Figma Make 복사본](https://www.figma.com/make/YSXPP4xr2PpdF9bjS9U2Xh/Implement-CampusRent-Home-Screen--Copy-): `RentalPages.tsx`, `RentalProvider.tsx`, `rental-records.ts`, `AdminPage.tsx`, `AdminInspectionPanel.tsx`, `equipment-inspection.ts`, 인증 코드와 장비·시설 시연 데이터 검토.
- 로컬 구현: `src/main/java/.../catalog/CatalogService.java` 및 Thymeleaf 화면. 현재 홈과 일부 탐색만 구현되어 있으며 DAO·Oracle 연결은 없음.

**원본 Make의 목표 기능과 현재 로컬에서 완성된 기능은 다릅니다.** 본 문서의 기능 매핑은 원본 Make와 요구사항을 기준으로 합니다. 로컬 홈에 아직 없는 승인·반납 화면 때문에 ERD가 불필요하거나 누락되었다고 판정하지 않았습니다. DB 연결·DDL 실행·동시성 시험은 수행하지 않았으며, 프로젝트 소스와 ERD 원본을 변경하지 않았습니다.

## 2. 화면·기능 → 테이블 매핑

판정에서 ‘대응’은 저장 구조가 있다는 뜻이며, 제약조건이나 서버 기능이 구현되었다는 뜻은 아닙니다.

| 화면/행동 | 기능 ID | 주요 테이블·필드 | 판정 및 준비 사항 |
| --- | --- | --- | --- |
| 회원가입·학생/관리자 로그인 | F01 | `APP_USER`: EMAIL, PASSWORD, USER_NAME, ROLE_CODE | 대응. 이메일 중복 기준, 비밀번호 해시 저장, 관리자 계정 생성 경로 확정 |
| 장비 목록·분류·검색 | F02 | `EQUIPMENT_TYPE`, `EQUIPMENT_MODEL`, `EQUIPMENT` | 대응. 사용 여부·대여 허용·운영상태를 함께 적용 |
| 모델·사양·기본 구성품 상세 | F03 | `SPEC_ITEM`, `MODEL_SPEC`, `EQUIPMENT_COMPONENT`와 위 장비 테이블 | 대응. 사양 항목과 모델의 품목 일치 검사 필요 |
| 장비 신청·최종 제출 | F04 | `RENT_REQUEST`, `REQUEST_ITEM` | 대응. 기간·소유자·최신 이용 가능 여부 검사, 항목 단위 저장 결과 정의 |
| 승인 전 취소 | F05, F20 | `REQUEST_ITEM.STATUS_CODE`, `REQUEST_STATUS_LOG` | 대응. 본인 pending 항목만 변경 |
| 내 신청·과거 신청·거절 사유 | F06, F11, F24 | `RENT_REQUEST`, `REQUEST_ITEM`, `REQUEST_STATUS_LOG`, 출고·반납·이용 테이블 | 대응. 처리 이력 조회 규칙과 과거 자원 정보 표시 정책은 보완 필요 |
| 학생 반납 신청 | F07 | `REQUEST_ITEM.STATUS_CODE`, `REQUEST_STATUS_LOG` | 대응. 별도 반납 신청 테이블은 필수 아님. `collected → return_requested`와 학생·시각 기록 |
| 장비·사양·구성품 관리 | F08 | 장비 6개 테이블: TYPE/MODEL/EQUIPMENT/COMPONENT/SPEC_ITEM/MODEL_SPEC | 대응. 관리 화면은 후속 구현, 연관 이력이 있으면 물리 삭제 금지 |
| 관리자 장비 승인·거절 | F09 | `REQUEST_ITEM`, `REQUEST_STATUS_LOG`, 장비·반납·점검 관련 테이블 | 대응. 서로 다른 신청의 동시 승인 중복을 막는 자원 단위 잠금 필요 |
| 장비 실제 출고·구성품 보존 | F12 | `EQUIPMENT_CHECKOUT`, `CHECKOUT_COMPONENT` | 대응. 신청 유형·출고 1회 보장·과거 기준 불변성 확인 |
| 반납 검수·보류 | F10 | `RETURN_INSPECTION`, `RETURN_COMPONENT`, `REQUEST_ITEM`, `EQUIPMENT_CHECK_LOG` | 대응. 이번 수량·누적 수량·손상 누적 규칙 및 동일 트랜잭션 처리 필요 |
| 추가 반환 재확인 | F29 | 같은 출고에 연결된 다음 `RETURN_INSPECTION` 회차와 `RETURN_COMPONENT` | 대응. 새 신청을 만들지 않음. 회차 충돌·초과 누적 반환 방지 필요 |
| 장비 점검 필요·완료·후속 승인 영향 | F12 | `EQUIPMENT.OPERATING_STATUS/ROW_VERSION`, `EQUIPMENT_CHECK_LOG`, 미해결 신청·반납 | 대응. 반납 완료와 장비 점검 해제는 별도 처리 |
| 다른 대여 기간 조회 | F16 | 장비 + 기간 확보 중인 `REQUEST_ITEM` + 미반납·점검 상태 | 조회로 가능. 결과를 저장할 별도 테이블은 필수 아님 |
| 대체 장비 조회·관계 편집 | F17 | `EQUIPMENT_ALTERNATIVE`, 장비·사양·구성품 + 확보 내역 | 대응. 방향성, 자기 자신 지정 방지, 설정자 권한 확인 |
| 시설 목록·상세·이용 가능 조회 | F19 | `FACILITY`, `FACILITY_HOURS`, `FACILITY_PURPOSE`, `FACILITY_BLOCK`와 확보 내역 | 대응. 요일별 시간 및 실제 미종료 이용도 검사 |
| 시설 신청·승인·거절 | F20, F22 | `RENT_REQUEST`, `REQUEST_ITEM`, `REQUEST_STATUS_LOG` + 시설 조건 | 대응. 시설 인원·목적 조건부 필수와 동시 승인 제어 필요 |
| 시설 정보·운영 시간·차단 관리 | F21 | `FACILITY`, `FACILITY_HOURS`, `FACILITY_PURPOSE`, `FACILITY_BLOCK` | 대응. 운영 변경과 기존 승인 예약 충돌 처리 정책 확정 |
| 시설 실제 이용 시작·종료 | F23 | `FACILITY_USAGE`, `REQUEST_ITEM`, `REQUEST_STATUS_LOG` | 대응. 장비 신청 연결 금지, 신청별 이용 기록 1개 보장 |
| 다른 시설 시간대·대체 시설 | F25 | 시설 조건·차단·확보 내역 조회, 선택 시 `REQUEST_ALTERNATIVE` | 대응. 조회 결과와 실제 예약 확보를 구분 |
| 목적별 추천·추천 이유·인원 확인 | F27 | `USE_PURPOSE`, `PURPOSE_KEYWORD`, `PURPOSE_EQUIPMENT_RULE`, `FACILITY_PURPOSE`, `FACILITY.CAPACITY` | 기본 구조 대응. 복합 목적·부정 표현·인원 해석은 서버 로직과 코드값 계약 필요 |
| 선택 목록·항목별 조건 | F28 | `SELECTION_ITEM` | 로그인 사용자용 구조. 비로그인 임시 선택은 브라우저 보관으로 구분. 서버 초안 복구 범위 결정 필요 |
| 선택한 대안의 원래 조건 보존 | F16/F17/F25 | `REQUEST_ALTERNATIVE`의 ORIGINAL_*와 `REQUEST_ITEM`의 최종 조건 | 최종 선택 1건 보존에 대응. 선택 초안 복구·변경 이력 전체 저장은 별도 범위 |
| 통계·연체 목록 | F13/F14/F26, 선택 범위 | 신청·실제 이용·출고·반납 집계 | 단순 조회는 추가 테이블 불필요. 보류·연체·실제 사용 시간의 집계 정의 필요 |
| 알림·취소 대기 | F15/F18, 선택 범위 | 전용 테이블 없음 | 현재 필수 범위의 결함은 아님. 구현하기로 하면 알림 수신/발송·읽음, 대기 순서·상태 등의 추가 설계 필요 |

## 3. DB 생성 전 확정해야 할 사항 — P0

### P0-1. 장비/시설 중 정확히 하나만 선택하도록 제한

현재 `REQUEST_ITEM`과 `SELECTION_ITEM`은 EQUIPMENT_ID와 FACILITY_ID를 모두 NULL 허용합니다. 다음 불법 데이터가 들어가지 않도록 CHECK가 필요합니다.

- 자원 유형이 장비인데 FACILITY_ID만 존재하는 행
- EQUIPMENT_ID와 FACILITY_ID가 둘 다 존재하는 행
- 두 FK 모두 없는 행

아래는 코드값을 E/F로 정한다고 가정한 **조건 예시**이며, 아직 확정 DDL이 아닙니다.

```sql
CHECK (
  (ITEM_KIND = 'E' AND EQUIPMENT_ID IS NOT NULL AND FACILITY_ID IS NULL)
  OR
  (ITEM_KIND = 'F' AND FACILITY_ID IS NOT NULL AND EQUIPMENT_ID IS NULL)
)
```

`REQUEST_ITEM`의 시설 신청은 PEOPLE_COUNT ≥ 1과 PURPOSE_ID NOT NULL도 강제해야 합니다. 선택 목록은 미완성 조건을 허용할 수 있으므로 신청과 같은 필수 조건을 무조건 적용하면 안 됩니다. 선택 목록의 기간은 둘 다 비어 있거나, 둘 다 존재하면서 종료 > 시작인 형태를 권장합니다.

Oracle CHECK는 NULL 때문에 결과가 UNKNOWN인 행을 허용할 수 있습니다. `CHECK(PEOPLE_COUNT > 0)`만으로 시설 신청의 NULL 인원을 막을 수 없으므로 조건부 `IS NOT NULL`을 명시해야 합니다. [Oracle 무결성 안내](https://docs.oracle.com/en/database/oracle/oracle-database/19/adfns/data-integrity.html)

### P0-2. 출고·실제 이용의 신청 유형과 1:1 관계

PDF에서 `EQUIPMENT_CHECKOUT.ITEM_KIND`, `FACILITY_USAGE.ITEM_KIND`가 FK로 표시됩니다. 생성 DDL에서 실제 연결 방식을 확인해야 합니다.

권장하는 일관된 방식:

- 부모 `REQUEST_ITEM`에 `UNIQUE(REQUEST_ITEM_ID, ITEM_KIND)`.
- 출고에서 `(REQUEST_ITEM_ID, ITEM_KIND)`를 위 부모 조합으로 참조하고 `CHECK(ITEM_KIND='E')`.
- 시설 이용에서는 같은 조합을 참조하고 `CHECK(ITEM_KIND='F')`.
- 두 자식 테이블 각각에 `UNIQUE(REQUEST_ITEM_ID)`로 신청 한 항목의 중복 출고·중복 실제이용 방지.

이 조합은 장비 신청이 시설 이용 기록에 연결되는 오류를 차단합니다. ITEM_KIND만 별도로 FK처럼 연결하거나 REQUEST_ITEM_ID만 검사하면 같은 보장이 아닙니다. 출고·이용 가능 상태 및 관리자 권한은 추가로 서버에서 검사합니다.

### P0-3. 승인 중복은 ROW_VERSION만으로 해결되지 않음

두 관리자가 같은 장비의 **서로 다른 신청 A/B**를 동시에 승인하면 A/B의 버전 검사 모두 성공할 수 있습니다. 두 사람 모두 ‘겹치는 승인 없음’을 조회하고 각각 승인하는 경쟁을 막아야 합니다.

권장 서버 트랜잭션:

1. 대상 `EQUIPMENT` 또는 `FACILITY` 행을 `SELECT ... FOR UPDATE`로 잠금.
2. 잠금을 얻은 뒤 최신 신청 상태·버전과 운영 조건을 재조회.
3. 같은 자원의 확보 내역을 기간 조건으로 재검사.
4. 신청 상태 변경·버전 증가·상태 이력을 같은 트랜잭션으로 저장.
5. 어느 단계든 실패하면 전체 롤백.

겹침 판단은 `[시작, 종료)`를 기준으로 `기존시작 < 새종료 AND 기존종료 > 새시작`을 권장합니다. 따라서 10~12시와 12~14시는 인접 일정이며, 준비·정리 시간을 적용한다면 그 정책에 따라 별도 보정합니다.

**빈 예약 결과만 잠그는 것은 충분하지 않습니다.** 아직 확보 내역이 없더라도 존재하는 자원 행을 잠가 직렬화해야 합니다. 시설 차단 등록·운영 변경과 장비 점검 변경도 같은 자원 잠금 규약을 따라야 검증 이후의 상태 변경과 충돌하지 않습니다. 여러 자원을 묶어 잠글 경우 잠금 순서도 통일합니다. 이는 Oracle 행 잠금 동작을 이용한 애플리케이션 설계 제안입니다. [Oracle DML 잠금 안내](https://docs.oracle.com/en/database/oracle/oracle-database/19/sqlrf/Automatic-Locks-in-DML-Operations.html)

원본 `rental-records.ts::reservationBlocks()`는 `approved`, `collected`, `return_requested`, `return_held`, `returned`를 확보 내역에 포함합니다. 프로젝트 문서도 조기 반납·종료 시 잔여 예정 기간을 자동 해제하지 않는 기준입니다. 따라서 **완료된 항목을 무조건 확보 조회에서 제외하면 원본과 동작이 달라집니다.** 예정 기간과 실제 이용·반납 시각을 별도로 유지해야 합니다.

단, 예정 기간이 지났다고 실제 미반납·미종료가 해결된 것은 아닙니다. 출고와 시설 이용 시작 시에는 이전 실제 이용 미종료 여부도 확인합니다.

### P0-4. 상태 코드·이력 저장 규칙

원본 장비 상태 흐름:

```text
pending → approved → collected → return_requested → return_held → returned
                                    └────────────────────────→ returned
pending → rejected
pending → cancelled
return_held → return_held  (추가 확인 후에도 부족한 경우)
```

원본 시설은 `pending → approved → collected → returned`이며 collected/returned를 화면에서는 ‘이용 중/이용 완료’로 표시합니다. 시설에 return_requested/return_held를 허용하지 않아야 합니다.

필요한 계약:

- DB 상태 코드, 화면 라벨, 자원 유형별 허용 전이표 작성.
- `REQUEST_ITEM.STATUS_CODE`와 `REQUEST_STATUS_LOG`를 항상 함께 저장.
- 최초 접수는 FROM_STATUS=NULL로 기록 가능. 승인·거절·취소·반납 신청의 처리자와 서버 시각 보존.
- 거절 전환에는 공백이 아닌 사유 필수. 반납 보류에는 `RETURN_INSPECTION.HOLD_REASON` 필수.
- 시설 ENDED_AT/ENDED_BY는 함께 입력되고 종료 ≥ 실제 시작이어야 함. ‘종료 시각만 입력’ 금지.
- 같은 상태를 유지한 추가 반납·점검 이벤트도 가능하므로 모든 이력에 FROM≠TO를 강제하지 않음.

승인자·거절 시각·학생 반납 신청 시각을 위한 컬럼이 REQUEST_ITEM에 없더라도, **이력에 빠짐없이 저장하고 조회하면 기능상 누락은 아닙니다.** 편의 컬럼을 추가한다면 어느 쪽이 기준 데이터인지 먼저 정합니다.

### P0-5. 출고 기준·반납 회차의 무결성과 트랜잭션

PDF의 복합키 구조를 생성 SQL에서 확인합니다.

- `CHECKOUT_COMPONENT`: PK `(CHECKOUT_ID, COMPONENT_SEQ)`.
- `RETURN_INSPECTION`: PK `(CHECKOUT_ID, INSPECTION_ROUND)`.
- `RETURN_COMPONENT`: PK `(CHECKOUT_ID, INSPECTION_ROUND, COMPONENT_SEQ)`.
- 반납 구성품은 `(CHECKOUT_ID, INSPECTION_ROUND)`로 해당 검수 회차를, `(CHECKOUT_ID, COMPONENT_SEQ)`로 **같은 출고의** 구성품 기준을 참조.

반납 누적 수량은 해당 출고·구성품의 이번 반환 수량을 합산하여 계산합니다. 출고 수량 2개에 1개+1개가 들어오면 2개이며, 1개+2개는 거절해야 합니다. 이 합계 검증은 다른 행을 참조하므로 단순한 행 CHECK로 해결하지 말고 출고/신청 잠금과 서버 트랜잭션으로 처리합니다.

추가 반환 저장 시 신청·장비의 최신 상태/버전, 기존 회차와 누적 수량을 재검사하고 다음 회차를 배정합니다. `MAX(회차)+1`만 잠금 없이 실행하면 경쟁이 생깁니다. 같은 회차 재전송에는 PK 오류 또는 이미 처리된 결과를 명확히 반환하고 수량을 재합산하지 않아야 합니다.

사후 출고 등록은 이미 지난 실제 시각이 불명확할 수 있으므로 `ACTUAL_CHECKOUT_AT` NULL 허용은 타당합니다. `REGISTERED_AT`은 등록 당시 서버 시각, `SOURCE_CODE`는 정상 출고/사후 등록을 구분하고 이후 출고 기준을 임의 변경하지 않습니다. 반납 조회를 현재 `EQUIPMENT_COMPONENT` 기준으로 다시 구성하면 안 됩니다.

### P0-6. UQ·일반 CHECK·기본값·ID 생성

최소 확인 목록:

| 대상 | 권장 사항 |
| --- | --- |
| APP_USER.EMAIL | 앞뒤 공백·대소문자 정규화 정책과 일치하는 UQ. 예: 정규화 저장 + UQ, 또는 LOWER(TRIM(EMAIL)) 기반 유일 인덱스 |
| 장비/시설/모델/접수/목적 코드 | ASSET_CODE, FACILITY_CODE, MODEL_CODE, REQUEST_NO, PURPOSE_CODE의 업무상 유일성 명시 |
| REQUEST_ITEM | `(REQUEST_ID, ITEM_NO)` UQ, ITEM_NO 양수 |
| Y/N 필드 | `IN ('Y','N')`, 각각의 초기값 명시 |
| ROW_VERSION | 기본 0, 음수 금지, 성공 저장마다 증가 |
| 신청/차단 기간 | 종료 > 시작. 신청 시작이 미래인지는 서버 현재 시각으로 검증 |
| 수량·회차·수용 인원 | 필요한 양수/0 이상 조건 명시. 정수 입력은 API에서도 확인 |
| 대체 장비 관계 | SOURCE≠TARGET, 방향성 유지, 동일 쌍 중복 방지 |
| 사양 값 | 모델의 TYPE_ID와 사양 항목의 TYPE_ID가 같은지 검사. 두 개의 독립 FK만으로는 이 의미 조건을 보장하지 못함 |
| FK와 삭제 | 신청·출고·반납·상태 이력은 연관 마스터 삭제로 연쇄 소실되지 않게 정책 명시 |
| 생성 시각/식별자 | 서버/DB 시각 기준 통일. Oracle 버전에 맞춰 IDENTITY 또는 SEQUENCE 선택 |

NUMBER(10) PK에 Make의 `cam01`·`room01` 또는 UUID를 그대로 넣을 수 없습니다. **DB PK와 화면용 코드/DTO 매핑을 분리**하면 되며 문자열을 저장하려고 PK 전체를 변경할 필요는 없습니다.

## 4. 화면과 DB가 달라질 수 있는 부분 — P1

### P1-1. 과거 신청의 이름·사양·시설 정보 보존

근거: `RentalItem = Resource & {...}`이고 `applyRecordChange()`는 신청 항목에 Resource 내용을 복사해 보관합니다. `AdminPage.tsx`의 과거 항목도 `ResourceInformation resource={selected.item}`으로 당시 저장된 모델·사양·구성품 등을 표시합니다.

ERD는 출고 이후 장비명·관리번호·구성품 스냅샷을 잘 보존하지만, `REQUEST_ITEM` 자체에는 자원명·관리번호·모델 스냅샷이 없습니다. 따라서 **출고 전 거절·취소된 장비 신청이나 시설 이력**은 현재 마스터를 JOIN하면 이름·사양 변경이 과거 화면에 반영됩니다.

결정할 것:

- 과거에도 최신 자원 정보를 보여줄 것인지, 신청 당시 정보를 보여줄 것인지.
- 당시 표시를 원하면 최소 자원명·관리번호 스냅샷을 REQUEST_ITEM에 추가하고, 모델·사양·시설 위치·비치 설비까지 보존할지는 별도로 정함.
- 상세 전체를 보존해야 한다면 요청별 상세 스냅샷 구조 또는 마스터 버전 구조를 검토. 무조건 모든 컬럼을 복제할 필요는 없음.

이 항목은 **원본 화면과 엄밀히 동일한 이력 표시를 원할 때의 실제 설계 차이**입니다. 이름 변경 후 과거 화면 확인 시험으로 정책을 검증해야 합니다.

### P1-2. ‘이번 회차 확인 안 함’과 ‘0개 반환 확인’ 구분

원본 `equipment-inspection.ts`의 `ReturnOutcome.checkedThisRound`는 두 경우를 구분합니다. 현재 RETURN_COMPONENT에 직접 대응하는 확인 여부 컬럼은 없습니다.

추가 컬럼 없이 가능한 권장안:

- 실제 확인한 구성품만 이번 RETURN_COMPONENT에 저장.
- 0개 반환을 확인한 경우는 RETURNED_QTY=0인 행을 저장.
- 이미 전부 확인되어 이번에 다시 보지 않은 품목은 이번 회차에 행을 저장하지 않음.
- 누적 반환과 손상은 이전 모든 회차에서 계산하여 화면의 전체 구성품 표를 재구성.

매 회차 모든 구성품 행을 스냅샷처럼 저장하려면 `CHECKED_THIS_ROUND_YN` 같은 컬럼을 추가해야 두 경우를 구분할 수 있습니다. 둘 중 하나를 선택하면 되며 **새 컬럼이 무조건 필요한 것은 아닙니다.** 이전 손상은 이후 정상 행 한 건으로 사라지지 않도록 누적 판단합니다.

### P1-3. 코드 길이와 화면·DB 코드 변환

`EQUIPMENT_CHECKOUT.SOURCE_CODE`는 VARCHAR2(20 CHAR)인데, 원본 정상 출고 값 `registered-demo-checkout`은 **23자**입니다. 그대로 저장하면 길이 제한에 걸립니다.

- 권장: DB용 짧은 코드 NORMAL/RETRO 등으로 명시적 변환.
- 대안: 원본 문자열을 유지해야 하면 길이를 늘림.

`ROLE_CODE`, `STATUS_CODE`, `OPERATING_STATUS`, `ORIGIN_CODE`, `NEED_LEVEL`, `MATCH_MODE`, `EFFECT_CODE`, `ACTION_CODE`, `OUTCOME_CODE`, `RETURN_CONDITION`도 같은 방식으로 허용 값·라벨·길이·변환표를 작성합니다. Figma의 한글 종류 값은 CHAR(1)에 직접 저장하지 않습니다.

### P1-4. 비로그인 선택과 로그인 후 초안 복구

SELECTION_ITEM.USER_ID NOT NULL은 기준 문서의 로그인 후 서버 저장 가정과 일치하므로, 비로그인 사용자 때문에 FK를 NULL 허용으로 바꿀 필요는 없습니다.

다만 아래를 결정해야 합니다.

- 로그인 후 선택 목록을 서버에 저장할지, 신청 직전까지 브라우저에만 둘지.
- 브라우저 선택과 기존 서버 선택을 합칠 때 동일 자원·다른 기간을 어떻게 처리할지.
- 선택 항목 조건 변경에도 다중 탭 충돌 검사가 필요한지. 필요하면 SELECTION_ITEM에 ROW_VERSION/UPDATED_AT 검토.
- 대체 선택의 원래 자원·기간을 브라우저가 최종 신청까지 전달할지, 서버 선택 초안에서도 복구할지. 후자를 원하면 선택 목록 측에도 대안 원본 조건을 보존할 구조가 필요함.

최종 신청 이후에는 REQUEST_ALTERNATIVE가 대응하지만, 이 테이블만으로 **신청 전 초안**까지 복구되지는 않습니다.

### P1-5. 운영 시간과 운영 정책

FACILITY_HOURS의 PK가 시설+요일이면 요일당 운영 구간 1개입니다. 현재 원본의 09:00~20:00 시연은 표현 가능합니다.

- 휴무일은 행 없음으로 처리할지 명시.
- 점심시간처럼 반복 분할 운영이 필요하면 운영 구간 순번을 키에 추가하거나 휴식 구간을 별도 규칙으로 표현.
- 특정 날짜의 점검·휴무는 FACILITY_BLOCK으로 표현 가능. 반복 휴무를 매일 복제할지 별도 정책화할지는 범위 결정.
- OPEN_TIME/CLOSE_TIME은 HH:mm 형식·유효 시간 범위를 검사. 자정 넘김을 허용하지 않는 현재 시연이면 OPEN_TIME<CLOSE_TIME.
- 최대 대여기간, 수령·반납 가능 시간, 준비·정리 시간, 승인 후 취소·미수령은 문서상 미결정 사항. 값이 확정되기 전 임의 숫자를 DB에 고정하지 않음.

`FACILITY_HOURS`, `FACILITY_PURPOSE`, `FACILITY_BLOCK` 변경 때도 부모 FACILITY 버전/잠금 기준을 갱신해야 오래된 조건으로 승인하는 일을 막을 수 있습니다.

## 5. 추가 테이블이 꼭 필요하지 않은 부분

- **예약 확보 전용 테이블:** 기준 문서는 REQUEST_ITEM의 상태·기간으로 판단하는 방식. 우선 이 방식으로 구현 가능. 별도 RESERVATION을 추가하면 상태·기간의 이중 관리가 생기므로 필요성을 먼저 검토.
- **학생 반납 신청 테이블:** 단일 반납 신청과 이후 재확인은 상태 이력 + 기존 검수 회차로 대응.
- **누적 반환 수량 컬럼:** RETURNED_QTY 합계와 DELIVERED_QTY 차이로 계산. 저장하면 일관성 유지 책임이 추가됨.
- **추천 결과 테이블:** 현재 규칙 기반 조회라면 필수 아님. 추천 당시 규칙/이유 재현이나 분석 이력을 원할 때만 규칙 버전·추천 이력 검토.
- **시설 추천 규칙 테이블:** FACILITY_PURPOSE·수용 인원과 서버 규칙으로 현재 흐름을 구현할 수 있음. 시설별 가중치·우선순위를 데이터로 관리하려는 경우에 확장.
- **별도 학생/관리자 테이블:** 현재 계정 입력과 역할은 APP_USER로 대응. 학생번호·학과·연락처가 실제 요구사항으로 추가될 때 검토.
- **로그인 세션 DB 테이블:** 서버 세션 운영 방식에 따라 달라지며 화면만으로 필수라고 판단할 수 없음.

APP_USER.PASSWORD(255)는 이름만으로 평문 저장이라고 단정할 수 없습니다. 실제 서버에서는 비밀번호 해시를 저장하고, 원본의 시연용 인증·고정 관리자 ID를 운영 인증으로 그대로 옮기지 않습니다.

## 6. 조회 및 저장 준비

### 주요 조회 조합

| 조회 | 기준 조합 |
| --- | --- |
| 장비 카드·상세 | EQUIPMENT → MODEL → TYPE, MODEL_SPEC → SPEC_ITEM, COMPONENT |
| 시설 상세·가능 여부 | FACILITY + 요일 HOURS + PURPOSE + BLOCK + 겹치는 REQUEST_ITEM + 실제 미종료 USAGE |
| 내 신청 | RENT_REQUEST.APPLICANT_ID → REQUEST_ITEM → 상태 이력·출고·반납/이용 |
| 관리자 대기 목록 | REQUEST_ITEM.STATUS_CODE + 자원 + 신청자 |
| 반납 검수 기준 | REQUEST_ITEM → EQUIPMENT_CHECKOUT → CHECKOUT_COMPONENT + 회차별 RETURN_COMPONENT 합계 |
| 점검으로 영향받는 승인 | EQUIPMENT + 미해결 반납/점검 + 같은 장비의 approved 신청 |
| 다른 일정/대체 자원 | 기존 자원/길이/인원/목적 유지 조건 + 대상 자원의 운영·확보·제한 조건 |

처리 시각이 같은 이력이 있을 수 있으므로 이력 정렬은 시각과 상태이력ID를 함께 사용합니다. ‘마지막 관리자/사유’가 아니라 승인·거절·반납 신청 등 **행동별 이력**을 조회해야 화면에 맞습니다.

인덱스 후보는 `RENT_REQUEST(APPLICANT_ID, REQUESTED_AT)`, `REQUEST_ITEM(REQUEST_ID, ITEM_NO)`, 장비/시설 각각의 `(자원ID, STATUS_CODE, USE_START_AT, USE_END_AT)`, `REQUEST_STATUS_LOG(REQUEST_ITEM_ID, CHANGED_AT, STATUS_LOG_ID)`, `FACILITY_BLOCK(FACILITY_ID, BLOCK_START_AT, BLOCK_END_AT)`, `EQUIPMENT_CHECK_LOG(EQUIPMENT_ID, CHECKED_AT)`입니다. 기존 PK/UQ 인덱스와 중복하지 않도록 생성 DDL·실행 계획·데이터 규모를 보고 선택합니다.

### DB 구축 작업 순서

1. Oracle 버전, MyBatis/JDBC, 날짜·시각 기준, 선택 목록 저장 범위 확정.
2. P0 제약조건·코드표·과거 표시 정책을 Erwin 모델에 반영하고 검토.
3. DDL 내보내기. 테이블·ID 생성·PK/UQ·CHECK·FK·기본값·인덱스를 확인하고 테스트 스키마에 적용.
4. 생성된 USER_CONSTRAINTS/USER_CONS_COLUMNS 등과 모델을 비교하여 적용된 관계·제약 확인.
5. 사용자·목적·품목·모델·사양·장비·시설·구성품·운영 조건 등의 가상 초기 데이터 작성. 실제 데이터와 IS_DEMO_YN 구분.
6. DAO/서비스를 붙이고 신청·승인·이력/검수 저장을 트랜잭션으로 구현.
7. 아래 업무 시나리오와 두 DB 세션을 이용한 경쟁 시험을 통과한 뒤 화면 연결.

## 7. DB 구현 완료 판정을 위한 필수 시험

| 시험 | 기대 결과 |
| --- | --- |
| 두 자원 FK 모두 입력/둘 다 누락/유형 불일치 | 거절 |
| 시설 신청에서 인원·목적 누락, 종료≤시작 | 거절 |
| 장비 신청에 시설 이용, 시설 신청에 장비 출고 연결 | 거절 |
| 같은 신청에 두 번 출고·두 번 시설 이용 기록 | 거절 |
| 관리자 2명이 같은 자원·겹치는 기간의 서로 다른 신청 승인 | 정확히 한 건만 성공, 다른 건 충돌/이용 불가 |
| pending 신청 여러 개 + 12시 종료/12시 시작 인접 신청 | pending은 확보하지 않음. 인접 일정은 정책상 허용 |
| 승인과 동시에 시설 차단/장비 점검 상태 변경 | 같은 잠금 규약으로 처리되어 최신 조건으로 판단 |
| 출고 이후 기본 구성품명·수량 변경 | 기존 출고·반납 기준은 불변 |
| 출고 2개 → 첫 회차 1개 → 다음 회차 1개 | 보류 후 완료, 누적 2개 |
| 누적 초과·검수 요청 재전송·두 창에서 같은 추가 반환 | 초과/중복 합산 차단, 오래된 버전 처리 실패 |
| 이미 반환한 품목을 다음 회차에서 생략 / 0개 반환을 명시 확인 | 두 경우가 저장·조회에서 구분됨 |
| 전량 반환했지만 손상 있음 | 대여 반납 완료와 장비 점검 제한을 별도로 유지 |
| 미반납·보류 상태에서 점검 완료만 요청 | 이용 제한 해제 불가 |
| 시설 종료/장비 조기 반납 | 실제 시각은 보존, 예정 확보 기간의 자동 단축 없음 |
| 다른 학생 취소/반납 요청, 학생의 관리자 API 호출 | 권한·소유권 검사로 거절 |
| 현재 자원 이름·사양 변경 후 거절/취소·시설 과거 이력 조회 | 확정한 스냅샷/최신 표시 정책과 일치 |
| 저장 중 이력 또는 구성품 INSERT 실패 | 상태만 성공하지 않고 전체 롤백 |

## 8. 팀에서 먼저 결정할 질문

1. 과거 신청 화면은 신청 당시 이름·관리번호·상세 사양을 보여야 하는가?
2. 로그인 후 선택 목록을 서버에 저장·복구하는가? 대체 선택의 원래 조건까지 복구하는가?
3. 반환 회차는 ‘확인한 품목만 행 저장’인가, ‘전체 품목 + 확인 여부 저장’인가?
4. Oracle 버전과 데이터 접근 기술은 무엇인가? PK 생성·배포 스크립트 기준을 정할 수 있는가?
5. 반복 분할 운영 시간과 실제 대여 정책까지 이번 범위에 포함하는가?

권장 출발점은 **기존 26개 테이블 유지 + P0 제약/트랜잭션 계약 확정**, 이후 과거 표시 정책에 필요한 최소 스냅샷과 선택 초안 복구 요구만 추가하는 것입니다.
