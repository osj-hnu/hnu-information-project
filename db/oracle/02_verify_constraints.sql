-- Run AFTER 01_schema.sql in the same application schema.
-- All fixture DML is rolled back. Sequence increments are NOT rolled back.
-- No DDL, no commits, no cleanup of existing application rows.
SET DEFINE OFF
SET SERVEROUTPUT ON
WHENEVER SQLERROR EXIT SQL.SQLCODE ROLLBACK

DECLARE
    v_student NUMBER := SEQ_APP_USER.NEXTVAL;
    v_admin NUMBER := SEQ_APP_USER.NEXTVAL;
    v_purpose NUMBER := SEQ_USE_PURPOSE.NEXTVAL;
    v_type NUMBER := SEQ_EQUIPMENT_TYPE.NEXTVAL;
    v_model NUMBER := SEQ_EQUIPMENT_MODEL.NEXTVAL;
    v_equipment NUMBER := SEQ_EQUIPMENT.NEXTVAL;
    v_facility NUMBER := SEQ_FACILITY.NEXTVAL;
    v_request NUMBER := SEQ_RENT_REQUEST.NEXTVAL;
    v_eq_item NUMBER := SEQ_REQUEST_ITEM.NEXTVAL;
    v_fac_item NUMBER := SEQ_REQUEST_ITEM.NEXTVAL;
    v_checkout NUMBER := SEQ_EQUIPMENT_CHECKOUT.NEXTVAL;
    v_checks PLS_INTEGER := 0;
    v_count PLS_INTEGER;
    v_suffix VARCHAR2(30) := TO_CHAR(v_request);

    PROCEDURE expect_error(p_label VARCHAR2, p_sql VARCHAR2, p_code NUMBER) IS
    BEGIN
        BEGIN
            EXECUTE IMMEDIATE p_sql;
        EXCEPTION
            WHEN OTHERS THEN
                IF SQLCODE = p_code THEN
                    v_checks := v_checks + 1;
                    DBMS_OUTPUT.PUT_LINE('PASS: ' || p_label || ' (' || SQLCODE || ')');
                    RETURN;
                END IF;
                RAISE;
        END;
        RAISE_APPLICATION_ERROR(-20001, 'Expected rejection did not occur: ' || p_label);
    END;

    FUNCTION item_sql(p_no NUMBER, p_kind VARCHAR2, p_equipment VARCHAR2,
                      p_facility VARCHAR2, p_people VARCHAR2, p_purpose VARCHAR2,
                      p_status VARCHAR2 := 'pending',
                      p_end VARCHAR2 := '2035-01-01 12:00:00') RETURN VARCHAR2 IS
    BEGIN
        RETURN 'INSERT INTO TBL_REQUEST_ITEM ' ||
            '(REQUEST_ITEM_ID, REQUEST_ID, ITEM_NO, ITEM_KIND, EQUIPMENT_ID, FACILITY_ID, ' ||
            'USE_START_AT, USE_END_AT, PEOPLE_COUNT, PURPOSE_ID, STATUS_CODE) VALUES (' ||
            'SEQ_REQUEST_ITEM.NEXTVAL,' || v_request || ',' || p_no || ',''' || p_kind || ''',' ||
            p_equipment || ',' || p_facility || ',TIMESTAMP ''2035-01-01 10:00:00'',TIMESTAMP ''' ||
            p_end || ''',' || p_people || ',' || p_purpose || ',''' || p_status || ''')';
    END;
BEGIN
    SAVEPOINT campus_schema_test;

    SELECT COUNT(*) INTO v_count FROM USER_TABLES WHERE TABLE_NAME LIKE 'TBL\_%' ESCAPE '\';
    IF v_count <> 26 THEN
        RAISE_APPLICATION_ERROR(-20002, 'Use dedicated schema; expected 26 TBL_ tables');
    END IF;
    SELECT COUNT(*) INTO v_count FROM USER_TAB_COLUMNS WHERE TABLE_NAME LIKE 'TBL\_%' ESCAPE '\';
    IF v_count <> 185 THEN
        RAISE_APPLICATION_ERROR(-20003, 'Expected 185 physical columns');
    END IF;
    SELECT COUNT(*) INTO v_count FROM USER_SEQUENCES WHERE SEQUENCE_NAME LIKE 'SEQ\_%' ESCAPE '\';
    IF v_count <> 17 THEN
        RAISE_APPLICATION_ERROR(-20004, 'Use dedicated schema; expected 17 SEQ_ sequences');
    END IF;
    SELECT COUNT(*) INTO v_count FROM USER_CONSTRAINTS
    WHERE TABLE_NAME LIKE 'TBL\_%' ESCAPE '\'
      AND (STATUS <> 'ENABLED' OR VALIDATED <> 'VALIDATED');
    IF v_count <> 0 THEN
        RAISE_APPLICATION_ERROR(-20005, 'Disabled or unvalidated constraints found');
    END IF;

    -- Hash column fixture only; not a real account password hash.
    INSERT INTO TBL_APP_USER (USER_ID, EMAIL, PASSWORD, USER_NAME, ROLE_CODE)
    VALUES (v_student, 'sqltest-student-' || v_student || '@example.invalid',
            'TEST_ONLY_NOT_A_LOGIN_HASH', 'SQL fixture student', 'STUDENT');
    INSERT INTO TBL_APP_USER (USER_ID, EMAIL, PASSWORD, USER_NAME, ROLE_CODE)
    VALUES (v_admin, 'sqltest-admin-' || v_admin || '@example.invalid',
            'TEST_ONLY_NOT_A_LOGIN_HASH', 'SQL fixture admin', 'ADMIN');
    INSERT INTO TBL_USE_PURPOSE (PURPOSE_ID, PURPOSE_CODE, PURPOSE_NAME)
    VALUES (v_purpose, 'SQLTEST-P-' || v_suffix, 'SQL fixture purpose');
    INSERT INTO TBL_EQUIPMENT_TYPE (TYPE_ID, TYPE_NAME, CATEGORY_LABEL)
    VALUES (v_type, 'SQL fixture type', 'SQL fixture category');
    INSERT INTO TBL_EQUIPMENT_MODEL (MODEL_ID, TYPE_ID, MODEL_CODE, MODEL_NAME)
    VALUES (v_model, v_type, 'SQLTEST-M-' || v_suffix, 'SQL fixture model');
    INSERT INTO TBL_EQUIPMENT
        (EQUIPMENT_ID, MODEL_ID, ASSET_CODE, EQUIPMENT_NAME, STORAGE_LOCATION)
    VALUES (v_equipment, v_model, 'SQLTEST-E-' || v_suffix, 'SQL fixture equipment', 'SQL fixture storage');
    INSERT INTO TBL_FACILITY
        (FACILITY_ID, FACILITY_CODE, FACILITY_NAME, FACILITY_TYPE, LOCATION_TEXT, CAPACITY)
    VALUES (v_facility, 'SQLTEST-F-' || v_suffix, 'SQL fixture facility', 'MEETING', 'SQL fixture location', 4);
    INSERT INTO TBL_FACILITY_PURPOSE (FACILITY_ID, PURPOSE_ID)
    VALUES (v_facility, v_purpose);
    INSERT INTO TBL_RENT_REQUEST (REQUEST_ID, REQUEST_NO, APPLICANT_ID)
    VALUES (v_request, 'SQLTEST-R-' || v_suffix, v_student);
    INSERT INTO TBL_REQUEST_ITEM
        (REQUEST_ITEM_ID, REQUEST_ID, ITEM_NO, ITEM_KIND, EQUIPMENT_ID, USE_START_AT, USE_END_AT)
    VALUES (v_eq_item, v_request, 1, 'E', v_equipment,
            TIMESTAMP '2035-01-01 10:00:00', TIMESTAMP '2035-01-01 12:00:00');
    INSERT INTO TBL_REQUEST_ITEM
        (REQUEST_ITEM_ID, REQUEST_ID, ITEM_NO, ITEM_KIND, FACILITY_ID,
         USE_START_AT, USE_END_AT, PEOPLE_COUNT, PURPOSE_ID)
    VALUES (v_fac_item, v_request, 2, 'F', v_facility,
            TIMESTAMP '2035-01-01 10:00:00', TIMESTAMP '2035-01-01 12:00:00', 3, v_purpose);

    -- RETRO explicitly supports an unknown actual historical checkout timestamp.
    INSERT INTO TBL_EQUIPMENT_CHECKOUT
        (CHECKOUT_ID, REQUEST_ITEM_ID, ASSET_CODE_SNAPSHOT,
         EQUIPMENT_NAME_SNAPSHOT, SOURCE_CODE, REGISTERED_BY)
    VALUES (v_checkout, v_eq_item, 'SQLTEST-E-' || v_suffix, 'Snapshot name', 'RETRO', v_admin);
    INSERT INTO TBL_CHECKOUT_COMPONENT
        (CHECKOUT_ID, COMPONENT_SEQ, COMPONENT_NAME, REQUIRED_QTY, DELIVERED_QTY,
         BODY_YN, REQUIRED_YN, OUT_CONDITION)
    VALUES (v_checkout, 1, 'Snapshot component', 2, 2, 'Y', 'Y', 'NORMAL');
    INSERT INTO TBL_RETURN_INSPECTION
        (CHECKOUT_ID, INSPECTION_ROUND, INSPECTED_BY, OUTCOME_CODE, HOLD_REASON)
    VALUES (v_checkout, 1, v_admin, 'HOLD', 'One component remains');
    INSERT INTO TBL_RETURN_COMPONENT
        (CHECKOUT_ID, INSPECTION_ROUND, COMPONENT_SEQ, RETURNED_QTY, RETURN_CONDITION)
    VALUES (v_checkout, 1, 1, 1, 'NORMAL');
    INSERT INTO TBL_FACILITY_USAGE (USAGE_ID, REQUEST_ITEM_ID, STARTED_AT, STARTED_BY)
    VALUES (SEQ_FACILITY_USAGE.NEXTVAL, v_fac_item, LOCALTIMESTAMP, v_admin);

    expect_error('both resource FKs',
        item_sql(3, 'E', TO_CHAR(v_equipment), TO_CHAR(v_facility), 'NULL', 'NULL'), -2290);
    expect_error('missing resource',
        item_sql(3, 'E', 'NULL', 'NULL', 'NULL', 'NULL'), -2290);
    expect_error('facility people required',
        item_sql(3, 'F', 'NULL', TO_CHAR(v_facility), 'NULL', TO_CHAR(v_purpose)), -2290);
    expect_error('facility purpose required',
        item_sql(3, 'F', 'NULL', TO_CHAR(v_facility), '3', 'NULL'), -2290);
    expect_error('invalid request period',
        item_sql(3, 'E', TO_CHAR(v_equipment), 'NULL', 'NULL', 'NULL',
                 'pending', '2035-01-01 09:00:00'), -2290);
    expect_error('equipment-only stage on facility',
        item_sql(3, 'F', 'NULL', TO_CHAR(v_facility), '3', TO_CHAR(v_purpose), 'return_held'), -2290);
    expect_error('duplicate request item number',
        item_sql(1, 'E', TO_CHAR(v_equipment), 'NULL', 'NULL', 'NULL'), -1);
    expect_error('email normalization',
        'INSERT INTO TBL_APP_USER (USER_ID,EMAIL,PASSWORD,USER_NAME) VALUES ' ||
        '(SEQ_APP_USER.NEXTVAL,''UPPER@example.invalid'',''TEST_HASH'',''Test'')', -2290);
    expect_error('rejection reason required',
        'INSERT INTO TBL_REQUEST_STATUS_LOG ' ||
        '(STATUS_LOG_ID,REQUEST_ITEM_ID,TO_STATUS,CHANGED_BY,REASON_TEXT) VALUES ' ||
        '(SEQ_REQUEST_STATUS_LOG.NEXTVAL,' || v_eq_item || ',''rejected'',' || v_admin || ',''   '')', -2290);
    expect_error('checkout cannot reference facility request',
        'INSERT INTO TBL_EQUIPMENT_CHECKOUT ' ||
        '(CHECKOUT_ID,REQUEST_ITEM_ID,ITEM_KIND,ASSET_CODE_SNAPSHOT,EQUIPMENT_NAME_SNAPSHOT,SOURCE_CODE,REGISTERED_BY)' ||
        ' VALUES (SEQ_EQUIPMENT_CHECKOUT.NEXTVAL,' || v_fac_item ||
        ',''E'',''TEST'',''TEST'',''RETRO'',' || v_admin || ')', -2291);
    expect_error('checkout once per request',
        'INSERT INTO TBL_EQUIPMENT_CHECKOUT ' ||
        '(CHECKOUT_ID,REQUEST_ITEM_ID,ASSET_CODE_SNAPSHOT,EQUIPMENT_NAME_SNAPSHOT,SOURCE_CODE,REGISTERED_BY)' ||
        ' VALUES (SEQ_EQUIPMENT_CHECKOUT.NEXTVAL,' || v_eq_item ||
        ',''TEST'',''TEST'',''RETRO'',' || v_admin || ')', -1);
    expect_error('facility usage cannot reference equipment request',
        'INSERT INTO TBL_FACILITY_USAGE (USAGE_ID,REQUEST_ITEM_ID,STARTED_AT,STARTED_BY)' ||
        ' VALUES (SEQ_FACILITY_USAGE.NEXTVAL,' || v_eq_item || ',LOCALTIMESTAMP,' || v_admin || ')', -2291);
    expect_error('facility end timestamp and actor must be paired',
        'UPDATE TBL_FACILITY_USAGE SET ENDED_AT=LOCALTIMESTAMP WHERE REQUEST_ITEM_ID=' || v_fac_item, -2290);
    expect_error('self alternative prohibited',
        'INSERT INTO TBL_EQUIPMENT_ALTERNATIVE ' ||
        '(SOURCE_EQUIPMENT_ID,TARGET_EQUIPMENT_ID,REASON_TEXT,CONFIGURED_BY) VALUES (' ||
        v_equipment || ',' || v_equipment || ',''TEST'',' || v_admin || ')', -2290);
    expect_error('return must reference original checkout component',
        'INSERT INTO TBL_RETURN_COMPONENT ' ||
        '(CHECKOUT_ID,INSPECTION_ROUND,COMPONENT_SEQ,RETURNED_QTY,RETURN_CONDITION) VALUES (' ||
        v_checkout || ',1,2,0,''NORMAL'')', -2291);
    expect_error('negative returned quantity',
        'UPDATE TBL_RETURN_COMPONENT SET RETURNED_QTY=-1 WHERE CHECKOUT_ID=' || v_checkout, -2290);
    expect_error('hold reason required',
        'INSERT INTO TBL_RETURN_INSPECTION (CHECKOUT_ID,INSPECTION_ROUND,INSPECTED_BY,OUTCOME_CODE)' ||
        ' VALUES (' || v_checkout || ',2,' || v_admin || ',''HOLD'')', -2290);
    expect_error('invalid facility clock time',
        'INSERT INTO TBL_FACILITY_HOURS (FACILITY_ID,WEEKDAY_NO,OPEN_TIME,CLOSE_TIME)' ||
        ' VALUES (' || v_facility || ',1,''25:00'',''26:00'')', -2290);
    expect_error('selection timestamps must be paired',
        'INSERT INTO TBL_SELECTION_ITEM ' ||
        '(SELECTION_ITEM_ID,USER_ID,ITEM_KIND,EQUIPMENT_ID,USE_START_AT) VALUES ' ||
        '(SEQ_SELECTION_ITEM.NEXTVAL,' || v_student || ',''E'',' || v_equipment || ',LOCALTIMESTAMP)', -2290);
    expect_error('normal checkout requires actual timestamp',
        'UPDATE TBL_EQUIPMENT_CHECKOUT SET SOURCE_CODE=''NORMAL'' WHERE CHECKOUT_ID=' || v_checkout, -2290);
    expect_error('damage requires explanation',
        'UPDATE TBL_RETURN_COMPONENT SET RETURN_CONDITION=''DAMAGED'',NOTE_TEXT=NULL WHERE CHECKOUT_ID=' ||
        v_checkout, -2290);

    -- Valid zero-return confirmation and next-round return: SUM remains 2, not 3.
    INSERT INTO TBL_RETURN_INSPECTION
        (CHECKOUT_ID, INSPECTION_ROUND, INSPECTED_BY, OUTCOME_CODE, HOLD_REASON)
    VALUES (v_checkout, 2, v_admin, 'HOLD', 'Checked, but no extra component returned');
    INSERT INTO TBL_RETURN_COMPONENT
        (CHECKOUT_ID, INSPECTION_ROUND, COMPONENT_SEQ, RETURNED_QTY, RETURN_CONDITION)
    VALUES (v_checkout, 2, 1, 0, 'NORMAL');
    INSERT INTO TBL_RETURN_INSPECTION
        (CHECKOUT_ID, INSPECTION_ROUND, INSPECTED_BY, OUTCOME_CODE)
    VALUES (v_checkout, 3, v_admin, 'COMPLETE');
    INSERT INTO TBL_RETURN_COMPONENT
        (CHECKOUT_ID, INSPECTION_ROUND, COMPONENT_SEQ, RETURNED_QTY, RETURN_CONDITION)
    VALUES (v_checkout, 3, 1, 1, 'NORMAL');
    SELECT SUM(RETURNED_QTY) INTO v_count FROM TBL_RETURN_COMPONENT
    WHERE CHECKOUT_ID = v_checkout AND COMPONENT_SEQ = 1;
    IF v_count <> 2 THEN
        RAISE_APPLICATION_ERROR(-20006, 'Cumulative return query failed');
    END IF;

    ROLLBACK TO campus_schema_test;
    DBMS_OUTPUT.PUT_LINE('PASS: 26 tables / 185 columns / 17 sequences');
    DBMS_OUTPUT.PUT_LINE('PASS: ' || v_checks || ' expected rejections and valid fixture paths');
    DBMS_OUTPUT.PUT_LINE('Fixture DML rolled back. Sequence values may have gaps.');
EXCEPTION
    WHEN OTHERS THEN
        ROLLBACK TO campus_schema_test;
        RAISE;
END;
/
