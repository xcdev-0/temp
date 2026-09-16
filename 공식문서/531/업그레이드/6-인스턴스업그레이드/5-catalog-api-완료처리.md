# 원문 — Completing the catalog-api service migration (5.3.x) `[2026-09-03 수집·전문]`

경로: 5.3.x → Administering → Post-installation setup (Day 1)
→ Setting up services → **Completing the catalog-api migration**
URL: https://www.ibm.com/docs/en/software-hub/5.3.x?topic=services-completing-catalog-api-migration
문서 갱신일: 2026-08-26
연결: 계획서 STEP 12 (No.115) — ★"생략 불가" 단계.
SWH업그레이드(STEP 10) 에서 catalog-api 이사 시작 →
서비스 전부 올린 뒤 이 절차로 마무리

> ★우리 판정:
> ```
> ① ★수집 완결 — 체크리스트 No.115 "Completing the catalog-api
>    migration" 의 실체. 이제 STEP 12 절차 전문 확보 (그동안 링크만)
> ② 자동/반자동 분기: oc describe ccs ccs-cr | grep
>    use_semi_auto... → 빈 응답=자동(4번 통계로 바로) /
>    true=반자동(2~3번 잡 확인·완료 후 4번). 모비스는 precheck
>    상 자동 예상(PVC 30Gi) → 대개 1·4·5·6 만
> ③ ★6단계 구조: 1방법확인 2잡상태(반자동만) 3완료patch(반자동만)
>    4통계 5★PostgreSQL 백업 6★통합(consolidation)
> ④ ★주의 — 5·6 은 "업그레이드 끝나고도 남는 후속작업":
>    5 PostgreSQL 백업(pg_dump, DB 크면 수시간) /
>    6 consolidation(거버넌스 카탈로그 자산 정합화, TIMEOUT 6000s)
>    → 24시간 창 밖으로 넘어갈 수 있음 — 일정 반영 필요 [잠정]
> ⑤ ★CouchDB 삭제(맨끝)는 "수 주 검증 후" — 당일 금지.
>    되돌릴 수 없음. Python3+requests 필요 (배스천 실측 항목 추가)
> ⑥ 스크립트 3종(migration_status.sh·backup_postgres.sh·
>    postgres-consolidation.sh) + 청소 스크립트 2종(py·sh) —
>    폐쇄망이라 미리 반출 후보 (precheck_migration.sh 처럼)
> ⑦ jq·python3·requests 전부 배스천에 있어야 — 실측 목록 확장
> ```

---

## 원문 전문

Completing the catalog-api service migration
Last Updated: 2026-08-26

After you upgrade the common core services from Version 5.1
to IBM Software Hub Version 5.3, the back-end database for
the catalog-api service is migrated from CouchDB to
PostgreSQL.

Who needs to complete this task?
- Instance administrator

When do you need to complete this task?
- Complete this task only if: ① upgraded from Version 5.1
  ② the instance includes the common core services.
- Repeat as needed (인스턴스마다)

### 1. Checking the migration method used

- 자동(automatic): CCS 가 마이그레이션 잡 완료를 기다린 뒤
  관련 컴포넌트를 업그레이드
- 반자동(semi-automatic): CCS 가 컴포넌트 업그레이드와
  동시에 마이그레이션 잡 실행

방법 판별:
```bash
oc describe ccs ccs-cr \
--namespace ${PROJECT_CPD_INST_OPERANDS} \
| grep use_semi_auto_catalog_api_migration
```
| 응답 | 유형 | 다음 |
|---|---|---|
| 빈 응답 | 자동 | 4. 통계 수집으로 |
| true | 반자동 | 2. 잡 상태 확인으로 |

### 2. Checking the status of the migration jobs
(반자동만 — 자동이면 4번으로)

잡: cams-postgres-migration-job / jobs-postgres-upgrade-migration
```bash
oc get job cams-postgres-migration-job jobs-postgres-upgrade-migration \
--namespace ${PROJECT_CPD_INST_OPERANDS} \
-o custom-columns=NAME:.metadata.name,STATUS:.status.conditions[0].type,COMPLETIONS:.status.succeeded
```
- Failed → IBM Support
- InProgress → 몇 분 후 재확인
- 둘 다 Complete → 3. 완료로

### 3. Completing the migration
(반자동만)

두 잡 완료 후 PostgreSQL 마이그레이션 완료:
Important: 이 단계 전 DB 업데이트 최소화 (쓰기 많으면
마이그레이션 시간 증가)
```bash
oc patch ccs ccs-cr \
--namespace ${PROJECT_CPD_INST_OPERANDS} \
--type merge \
--patch '{"spec": {"continue_semi_auto_catalog_api_migration": true}}'
```
CCS Completed 대기 (최소 10분, 변경 많으면 더). 확인:
```bash
oc get ccs ccs-cr --namespace ${PROJECT_CPD_INST_OPERANDS}
# NAME VERSION RECONCILED STATUS PERCENT AGE
# ccs-cr 11.0.0 11.0.0 Completed 100% 1d
```
- Failed → IBM Support / InProgress → 재확인 / Complete → 4번

### 4. Collecting statistics about the migration

migration_status.sh 로 마이그레이션된 DB·자산 수 확인
(디버깅용). 클라이언트 워크스테이션에 저장:

```bash
#!/bin/bash

# Set postgres connection parameters
postgres_password=$(oc get secret -n ${PROJECT_CPD_INST_OPERANDS} ccs-cams-postgres-app -o json 2>/dev/null | jq -r '.data."password"' | base64 -d)
postgres_username=cams_user
postgres_db=camsdb
postgres_migrationdb=camsdb_migration

echo -e "======MIGRATION STATUS==========="

# Total migrated database(s)
databases=$(oc -n ${PROJECT_CPD_INST_OPERANDS} -c postgres exec ccs-cams-postgres-1 -- psql -t postgresql://$postgres_username:$postgres_password@localhost:5432/$postgres_migrationdb -c "select count(*) from migration.status where state='complete'" 2>/dev/null)
if [ -n "$databases" ];then
  databases_no_space=$(echo "$databases" | tr -d ' ')
  echo "Total catalog-api databases migrated: $databases_no_space"
else
  echo "Unable to fetch migration information for databases"
fi

# Total migrated assets
assets=$(oc -n ${PROJECT_CPD_INST_OPERANDS} -c postgres exec ccs-cams-postgres-1 -- psql -t postgresql://$postgres_username:$postgres_password@localhost:5432/$postgres_db -c "select count(*) from cams.asset" 2>/dev/null)
if [ -n "$assets" ];then
  assets_no_space=$(echo "$assets" | tr -d ' ')
  echo -e "Total catalog-api assets migrated: $assets_no_space\n"
else
  echo "Unable to fetch migration information for assets"
fi
```
```bash
./migration_status.sh
```
→ 5. PostgreSQL 백업으로

### 5. Backing up the PostgreSQL database

새 PostgreSQL DB 백업. backup_postgres.sh 저장:

```bash
#!/bin/bash

# Make sure PROJECT_CPD_INST_OPERANDS is set
if [ -z "$PROJECT_CPD_INST_OPERANDS" ]; then
  echo "Environment variable PROJECT_CPD_INST_OPERANDS is not defined. This environment variable must be set to the project where IBM Software Hub is running."
  exit 1
fi

echo "PROJECT_CPD_INST_OPERANDS namespace is: $PROJECT_CPD_INST_OPERANDS"

# Step 1: Find the replica pod
REPLICA_POD=$(oc get pods -n $PROJECT_CPD_INST_OPERANDS -l app=ccs-cams-postgres -o jsonpath='{range .items[?(@.metadata.labels.role=="replica")]}{.metadata.name}{"\n"}{end}')

if [ -z "$REPLICA_POD" ]; then
  echo "No replica pod found."
  exit 1
fi

echo "Replica pod: $REPLICA_POD"

# Step 2: Extract JDBC URI from a secret
JDBC_URI=$(oc get secret ccs-cams-postgres-app -n $PROJECT_CPD_INST_OPERANDS -o jsonpath="{.data.uri}" | base64 -d)

if [ -z "$JDBC_URI" ]; then
  echo "JDBC URI not found in secret."
  exit 1
fi

#  Set path on the pod to save the dump file
TARGET_PATH="/var/lib/postgresql/data/forpgdump"

# Step 3: Run pg_dump with nohup inside the pod
oc exec "$REPLICA_POD" -n $PROJECT_CPD_INST_OPERANDS -- bash -c "
  TARGET_PATH=\"$TARGET_PATH\"
  JDBC_URI=\"$JDBC_URI\"
  echo \"TARGET_PATH is $TARGET_PATH\"
  mkdir -p $TARGET_PATH &&
  chmod 777 $TARGET_PATH &&
  nohup bash -c '
    pg_dump $JDBC_URI -Fc -f $TARGET_PATH/cams_backup.dump > $TARGET_PATH/pgdump.log 2>&1 &&
    echo \"Backup succeeded. Please copy $TARGET_PATH/cams_backup.dump file from this pod to a safe place and delete it on this pod to save space.\" >> $TARGET_PATH/pgdump.log
  ' &
  echo \"pg_dump started in background. Logs: $TARGET_PATH/pgdump.log\"
"
```
※원문 스크립트 내부는 파드 안에서 nohup 사용 — 이건
IBM 스크립트 원본 그대로 (우리 tmux 규칙은 배스천 쉘 기준,
파드 내부 백그라운드는 별개)

이어서 (백업 모니터링):
```bash
./backup_postgres.sh

REPLICA_POD=$(oc get pods -n ${PROJECT_CPD_INST_OPERANDS} -l app=ccs-cams-postgres -o jsonpath='{range .items[?(@.metadata.labels.role=="replica")]}{.metadata.name}{"\n"}{end}')
oc rsh ${REPLICA_POD}
cd /var/lib/postgresql/data/forpgdump/
ls -lat
```
- 진행 중: pgdump.log 크기 증가
- 완료: "Backup succeeded. Please copy ... cams_backup.dump"
- 실패: pgdump.log 에 에러 → IBM Support (pgdump.log 첨부)
- ★DB 크면 수시간

완료 후 안전한 곳으로 복사:
```bash
export POSTGRES_BACKUP_STORAGE_LOCATION=<directory>
oc cp ${REPLICA_POD}:/var/lib/postgresql/data/forpgdump/cams_backup.dump \
$POSTGRES_BACKUP_STORAGE_LOCATION/cams_backup.dump
oc rsh $REPLICA_POD rm -f /var/lib/postgresql/data/forpgdump/cams_backup.dump
```
→ 6. 통합으로

### 6. Consolidating the PostgreSQL database

거버넌스 카탈로그 전반의 동일 데이터 복사본을 단일 레코드로
통합 (동일 자산이 공통 속성 공유하도록). postgres-
consolidation.sh 저장 (재시도 로직 MAX_RETRIES=2, 자산
모니터링 TIMEOUT=6000s):

```bash
#!/bin/bash
#set -x

# Maximum number of retry attempts
MAX_RETRIES=2
RETRY_COUNT=0

# Function to run the consolidation process
run_consolidation() {
    local attempt=$1
    local skip_restart=$2
    echo "==========================================" >&2
    echo "Consolidation Attempt: $attempt of $MAX_RETRIES" >&2
    echo "==========================================" >&2

    # Step 1: Validating environment variables
    if [ -z "$PROJECT_CPD_INST_OPERANDS" ]; then
        echo "ERROR: Environment variable PROJECT_CPD_INST_OPERANDS is not defined for namespace where CPD is running." >&2
        exit 1
    fi
    echo "✓ PROJECT_CPD_INST_OPERANDS namespace is: $PROJECT_CPD_INST_OPERANDS" >&2

    # Step 2: Find the replica pod
    REPLICA_POD=$(oc get pods -n $PROJECT_CPD_INST_OPERANDS -l app=ccs-cams-postgres -o jsonpath='{range .items[?(@.metadata.labels.role=="replica")]}{.metadata.name}{"\n"}{end}')
    if [ -z "$REPLICA_POD" ]; then
        echo "ERROR: No replica pod found." >&2
        exit 1
    fi
    echo "✓ Replica pod: $REPLICA_POD" >&2

    # Step 3: Extract JDBC URI from a secret
    JDBC_URI=$(oc get secret ccs-cams-postgres-app -n $PROJECT_CPD_INST_OPERANDS -o jsonpath="{.data.uri}" | base64 -d)
    if [ -z "$JDBC_URI" ]; then
        echo "ERROR: JDBC URI not found in secret." >&2
        exit 1
    fi
    echo "✓ JDBC URI extracted successfully" >&2

    # Step 4: Mark catalogs as opt in
    oc exec "$REPLICA_POD" -n $PROJECT_CPD_INST_OPERANDS -- bash -c "psql -d ${JDBC_URI} -c \"UPDATE cams.catalog SET is_sharing_properties = 'true', optimistic_lock_id = optimistic_lock_id + 1 WHERE id in (SELECT id FROM cams.catalog where container_type = 'catalog' and (is_governed='true' or subtype='ibm_data_product_catalog')) and catalog.bss_account = '999';COMMIT;\"" >&2

    # Step 5: Rolling restart of catalog-api (skip on retries)
    if [ "$skip_restart" != "true" ]; then
        oc rollout restart deployment/catalog-api -n $PROJECT_CPD_INST_OPERANDS >&2
        oc rollout status deployment/catalog-api -n $PROJECT_CPD_INST_OPERANDS >&2
    fi

    # Step 6: Initialize content
    ICP4D_URL=$(oc get route cpd -o json | grep -i "host\"" | head -n 1 | awk -F '"' '{print $4}')
    AUTH_TOKEN=$(oc get secret wdp-service-id -o yaml | grep "service-id-credentials:" | head -n 1 | awk -F ": " '{print $2}'| base64 -d  | xargs)
    curl -k -X PUT "https://$ICP4D_URL/v2/shared_assets/initialize_content?bss_account_id=999" \
         -H "Authorization: Basic $AUTH_TOKEN" >&2

    # Step 7: Monitor asset consolidation (TIMEOUT 6000s, INTERVAL 30s)
    TIMEOUT=6000; INTERVAL=30; ASSET_NUM=1; start_time=$SECONDS
    while [ "$ASSET_NUM" -ne 0 ]; do
        if (( SECONDS - start_time >= TIMEOUT )); then
            echo "ERROR: Timeout reached after $TIMEOUT seconds. Exiting script." >&2
            exit 1
        fi
        ASSET_NUM=$(oc exec "$REPLICA_POD" -n $PROJECT_CPD_INST_OPERANDS -- bash -c "psql -d ${JDBC_URI} -c \"SELECT COUNT(resource_key) as asset_count FROM ( SELECT DISTINCT ON (resource_key) resource_key, catalog_id, asset_id from cams.asset where is_revision='false' and state = 'available' and asset_type = 'data_asset' and set_id is NULL and metadata->>'is_branched' = 'false' and (resource_key like '%|%' or identity_key like '%|%') and (catalog_id in (SELECT id FROM cams.catalog where is_sharing_properties = 'true' and container_type = 'catalog' and state = 'active' and bss_account = '999'))) AS distinct_assets;\"" | head -3 | tail -1 | tr -d '[:blank:]')
        echo "  → Assets remaining: $ASSET_NUM" >&2
        if [ "$ASSET_NUM" -ne 0 ]; then sleep $INTERVAL; fi
    done

    # Step 8: Final verification → 남은 자산 수 stdout 반환
    FINAL_ASSET_NUM=$(oc exec "$REPLICA_POD" -n $PROJECT_CPD_INST_OPERANDS -- bash -c "psql -d ${JDBC_URI} -c \"SELECT COUNT(resource_key) as asset_count FROM ( SELECT DISTINCT ON (resource_key) resource_key, catalog_id, asset_id from cams.asset where is_revision='false' and state = 'available' and asset_type = 'data_asset' and set_id is NULL and (resource_key like '%|%' or identity_key like '%|%' or resource_key ~ '[0-9a-f]{8}-...' or identity_key ~ '...') and (catalog_id in (SELECT id FROM cams.catalog where is_sharing_properties = 'true' and state = 'active' and container_type = 'catalog' and bss_account = '999'))) AS distinct_assets;\"" | head -3 | tail -1 | tr -d '[:blank:]')
    echo "$FINAL_ASSET_NUM"
}

# Main retry loop
echo "=========================================="
echo "Starting Consolidation Script with Retry Logic"
echo "Maximum retries: $MAX_RETRIES"
echo "=========================================="

while [ $RETRY_COUNT -lt $MAX_RETRIES ]; do
    RETRY_COUNT=$((RETRY_COUNT + 1))

    # Run consolidation and capture the remaining asset count
    # Skip restart on retry attempts (attempt > 1)
    if [ $RETRY_COUNT -gt 1 ]; then
        REMAINING_ASSETS=$(run_consolidation $RETRY_COUNT "true")
    else
        REMAINING_ASSETS=$(run_consolidation $RETRY_COUNT "false")
    fi

    # Handle empty or non-numeric values
    if [ -z "$REMAINING_ASSETS" ] || ! [[ "$REMAINING_ASSETS" =~ ^[0-9]+$ ]]; then
        echo "=========================================="
        echo "ERROR: Could not determine remaining asset count on attempt $RETRY_COUNT"
        echo "Received value: '$REMAINING_ASSETS'"
        echo "=========================================="
        exit 1
    fi

    if [ "$REMAINING_ASSETS" -eq 0 ]; then
        echo ""
        echo "=========================================="
        echo "✓ SUCCESS: Initial consolidation complete on attempt $RETRY_COUNT"
        echo "=========================================="
        exit 0
    else
        echo ""
        echo "=========================================="
        echo "⚠ Initial consolidation incomplete on attempt $RETRY_COUNT"
        echo "Remaining assets: $REMAINING_ASSETS"

        if [ $RETRY_COUNT -lt $MAX_RETRIES ]; then
            echo "Retrying... (Attempt $((RETRY_COUNT + 1)) of $MAX_RETRIES)"
            echo "Waiting 60 seconds before retry..."
            echo "=========================================="
            sleep 60
        else
            echo "=========================================="
            echo "⚠ Maximum retry attempts ($MAX_RETRIES) reached."
            echo "Initial consolidation incomplete after $MAX_RETRIES attempts."
            echo ""
            echo "Generating remaining_assets.csv and processing via API..."
            echo "=========================================="

            # Get required variables
            ICP4D_URL=$(oc get route cpd -o json | grep -i "host\"" | head -n 1 | awk -F '"' '{print $4}')
            REPLICA_POD=$(oc get pods -n $PROJECT_CPD_INST_OPERANDS -l app=ccs-cams-postgres -o jsonpath='{range .items[?(@.metadata.labels.role=="replica")]}{.metadata.name}{"\n"}{end}')
            JDBC_URI=$(oc get secret ccs-cams-postgres-app -n $PROJECT_CPD_INST_OPERANDS -o jsonpath="{.data.uri}" | base64 -d)
            AUTH_TOKEN=$(oc get secret wdp-service-id -o yaml | grep "service-id-credentials:" | head -n 1 | awk -F ": " '{print $2}'| base64 -d  | xargs)

            # Generate CSV with remaining assets (INCLUDES UUID patterns, NO is_branched check)
            echo "Querying remaining assets..."
            oc exec "$REPLICA_POD" -n $PROJECT_CPD_INST_OPERANDS -- bash -c "psql -d ${JDBC_URI} -t -A -F',' -c \"SELECT catalog_id, asset_id FROM ( SELECT DISTINCT ON (resource_key) resource_key, catalog_id, asset_id from cams.asset where is_revision='false' and state = 'available' and asset_type = 'data_asset' and set_id is NULL and (resource_key like '%|%' or identity_key like '%|%' or resource_key ~ '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}' or identity_key ~ '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}') and (catalog_id in (SELECT id FROM cams.catalog where is_sharing_properties = 'true' and container_type = 'catalog' and state = 'active' and bss_account = '999'))) AS distinct_assets;\"" > remaining_assets.csv

            echo "✓ Remaining assets saved to remaining_assets.csv"

            # Process each asset via API
            echo ""
            echo "Processing remaining assets via API..."
            TOTAL_ASSETS=$(wc -l < remaining_assets.csv | tr -d '[:blank:]')
            CURRENT=0
            FAILED=0

            while IFS=',' read -r catalog_id asset_id; do
                # Skip empty lines
                if [ -z "$catalog_id" ] || [ -z "$asset_id" ]; then
                    continue
                fi

                CURRENT=$((CURRENT + 1))
                echo "[$CURRENT/$TOTAL_ASSETS] Processing asset: catalog_id=$catalog_id, asset_id=$asset_id"

                # Call the API for each asset
                HTTP_CODE=$(curl -k -s -o /dev/null -w "%{http_code}" -X PUT \
                    "https://$ICP4D_URL/v2/shared_assets/initialize_content?bss_account_id=999&asset_id=$asset_id&catalog_id=$catalog_id" \
                    -H "Authorization: Basic $AUTH_TOKEN")

                if [ "$HTTP_CODE" -ge 200 ] && [ "$HTTP_CODE" -lt 300 ]; then
                    echo "  ✓ Success (HTTP $HTTP_CODE)"
                else
                    echo "  ✗ Failed (HTTP $HTTP_CODE) for asset_id: $asset_id and catalog_id : $catalog_id"
                    FAILED=$((FAILED + 1))
                fi

                # Small delay to avoid overwhelming the API
                sleep 1
            done < remaining_assets.csv

            echo ""
            echo "=========================================="
            echo "API Processing Complete"
            echo "Total assets processed: $TOTAL_ASSETS"
            echo "Failed: $FAILED"
            echo "Successful: $((TOTAL_ASSETS - FAILED))"
            echo "=========================================="

            if [ $FAILED -gt 0 ]; then
                echo "⚠ Some assets failed to process. Check the output above for details."
                exit 1
            else
                echo "✓ All remaining assets processed successfully"
                exit 0
            fi
        fi
    fi
done
```

실행:
```bash
chmod +x postgres-consolidation.sh
${OC_LOGIN}
./postgres-consolidation.sh
```
- ★최종 asset count = 0 이어야 성공. 0 아니면 재실행,
  그래도 0 아니면 IBM Support

### What to do if the consolidation completed successfully

★consolidation 성공 후 **수 주 동안** 프로젝트·카탈로그·
스페이스 정상 동작 확인. 그 후에야 마이그레이션 리소스 청소:
```bash
oc delete pod    -n ${PROJECT_CPD_INST_OPERANDS} -l app=cams-postgres-migration-app
oc delete job    -n ${PROJECT_CPD_INST_OPERANDS} -l app=cams-postgres-migration-app
oc delete cm     -n ${PROJECT_CPD_INST_OPERANDS} -l app=cams-postgres-migration-app
oc delete secret -n ${PROJECT_CPD_INST_OPERANDS} -l app=cams-postgres-migration-app
oc delete pvc cams-postgres-migration-pvc -n ${PROJECT_CPD_INST_OPERANDS}
```

### Cleaning up CouchDB databases

⚠Attention: CouchDB DB 영구 삭제 — IKC 정상(프로젝트·
카탈로그·자산 전부 확인) 검증 전 금지. 되돌릴 수 없음.

전제: 클라이언트에 Python 3 + requests 모듈
```bash
python3 --version
python3 -m pip install requests
```

절차: couchdb_cleanup 디렉토리 생성 후 아래 3파일 저장.

**couchdb_route.yaml** (wdp-couchdb-svc 로 Route):
```yaml
kind: Route
apiVersion: route.openshift.io/v1
metadata:
  labels:
    app: couchdb-route
  name: couchdb-route
spec:
  to:
    kind: Service
    name: wdp-couchdb-svc
  port:
    targetPort: https
  tls:
    termination: passthrough
    insecureEdgeTerminationPolicy: None
  wildcardPolicy: None
```

**cpd_catalog_api_post_migration_couchdb_cleanup.py**
(v2_ prefix DB 를 스레드풀로 삭제):
```python
#!/usr/bin/env python3
# coding: utf-8

import requests
import json
import argparse
from concurrent.futures import ThreadPoolExecutor
import threading

# Thread-safe counters
successful_deletes = 0
failed_deletes = 0
counter_lock = threading.Lock()

def list_dbs(db_list, db_prefix):
    """List databases matching the prefix"""
    if not db_list:
        print("\nNo databases found matching prefix '{}'".format(db_prefix))
        return

    print("\nDatabases matching prefix '{}':\n".format(db_prefix))
    print("=" * 50)
    for db in db_list:
        print(db)
    print("=" * 50)
    print("\nTotal databases found: {}".format(len(db_list)))

def delete_db(db, auth, hostname, verify_ssl):
    """Delete a single database and update counters"""
    global successful_deletes, failed_deletes

    url = hostname + db
    response = requests.delete(url, auth=auth, verify=verify_ssl)

    with counter_lock:
        if response.status_code == 200:
            print("Successfully deleted database: {}".format(db))
            successful_deletes += 1
        else:
            print("Failed to delete database: {} (Status code: {})".format(
                db, response.status_code))
            failed_deletes += 1

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("-p", "--cloudantpassword", required=True,
                        help="ci cloudant password")
    parser.add_argument("-t", "--threads", type=int, default=5,
                        help="number of threads to use (default: 5)")
    parser.add_argument("-H", "--hostname", required=True,
                        help="hostname of the Cloudant instance.")
    parser.add_argument("-u", "--username", required=True,
                        help="username for Cloudant authentication")
    parser.add_argument("-r", "--remove-cams-dbs", required=False,
                        help="delete all dbs belonging to CAMS")
    parser.add_argument("-l", "--list-cams-dbs", required=False,
                        help="list all dbs belonging to CAMS")
    parser.add_argument("--insecure-skip-tls-verify", action="store_true",
                        help="If true, the server's certificate will not be checked for validity. This will make your HTTPS connections insecure")
    args = parser.parse_args()

    password = str(args.cloudantpassword)
    hostname = args.hostname
    username = args.username
    remove_cams_dbs = args.remove_cams_dbs
    list_cams_dbs = args.list_cams_dbs
    verify_ssl = not args.insecure_skip_tls_verify

    # Validate that exactly one of remove-cams-dbs or list-cams-dbs is provided
    options_provided = sum([bool(remove_cams_dbs), bool(list_cams_dbs)])

    if options_provided == 0:
        parser.error("Error: One of --remove-cams-dbs or --list-cams-dbs must be provided")

    if options_provided > 1:
        parser.error("Error: Cannot specify both --remove-cams-dbs and --list-cams-dbs. Please provide only one")

    # Set db_prefix to 'v2_' for CAMS databases
    db_prefix = 'v2_'

    # Ensure hostname ends with a slash
    if not hostname.endswith('/'):
        hostname += '/'

    url = hostname + "_all_dbs"
    print("Cloudant instance: {}".format(url))

    response = requests.get(url, auth=(username, password), verify=verify_ssl)
    print("Response status: {}\n".format(response.status_code))

    all_dbs = json.loads(response.text)

    # Filter databases by prefix
    db_list = [db for db in all_dbs if db.startswith(db_prefix)]

    total_dbs = len(db_list)
    total_filtered = len(all_dbs) - total_dbs

    print("Found {} total databases".format(len(all_dbs)))
    print("Filtered {} databases that don't start with '{}' prefix".format(total_filtered, db_prefix))
    print("Found {} databases matching prefix\n".format(total_dbs))

    # If list-cams-dbs is set, just list the databases and exit
    if list_cams_dbs:
        list_dbs(db_list, db_prefix)
        return

    # Check if there are any databases to delete
    if not db_list:
        print("No databases found to delete with prefix '{}'".format(db_prefix))
        return

    # Create thread pool and execute deletions
    with ThreadPoolExecutor(max_workers=args.threads) as executor:
        # Create list of auth tuples for each task
        auth_list = [(username, password)] * len(db_list)
        hostname_list = [hostname] * len(db_list)
        verify_ssl_list = [verify_ssl] * len(db_list)

        # Map the delete_db function across all databases
        executor.map(lambda x: delete_db(*x), zip(db_list, auth_list, hostname_list, verify_ssl_list))

    print("\nDeletion Summary:")
    print("----------------")
    print("Total databases processed: {}".format(total_dbs))
    print("Successfully deleted: {}".format(successful_deletes))
    print("Failed to delete: {}".format(failed_deletes))

if __name__ == "__main__":
    main()
```

**cpd_catalog_api_post_migration_cleanup.sh** (list_dbs/remove_dbs 래퍼):
※원문 주의: 래퍼가 호출하는 파이썬 파일명이 원문상
`...cleanup.py` 로 되어 있으나 위 py 파일명은
`...couchdb_cleanup.py` — 현장에서 파일명 일치 확인 필요 [원문 표기]
```bash
#!/bin/bash

set -e

SCRIPT_DIR=$(dirname $(readlink -f "$0"))

usage() {
    cat <<EOF
This is a wrapper script to list existing catalog-api databases and remove those databases.

Usage: cpd_catalog_api_post_migration_cleanup.sh <action>

Arguments:
    <action>    Action to perform: remove_dbs or list_dbs

Examples:
    cpd_catalog_api_post_migration_cleanup.sh remove_dbs
    cpd_catalog_api_post_migration_cleanup.sh list_dbs

EOF
    exit 1;
}

function create_couchdb_route {
    oc apply -f "${SCRIPT_DIR}/couchdb_route.yaml"
}

function run_cleanup {
    route_host=$(oc get route couchdb-route -o jsonpath='{.spec.host}')
    couchdb_url="https://$route_host"
    couchdb_user=admin
    couchdb_password=$(oc get secret wdp-couchdb -o jsonpath='{.data.adminPassword}' | base64 -d)

    curl -k -s "$couchdb_url" > /dev/null # ensure that the URL is active

    if [ "$ACTION" == "remove_dbs" ]; then
        echo "Removing CAMS databases..."
        python3 "${SCRIPT_DIR}/cpd_catalog_api_post_migration_cleanup.py" \
            -H "$couchdb_url" \
            -u "$couchdb_user" \
            -p "$couchdb_password" \
            --remove-cams-dbs true \
            --insecure-skip-tls-verify
    elif [ "$ACTION" == "list_dbs" ]; then
        echo "Listing CAMS databases..."
        python3 "${SCRIPT_DIR}/cpd_catalog_api_post_migration_cleanup.py" \
            -H "$couchdb_url" \
            -u "$couchdb_user" \
            -p "$couchdb_password" \
            --list-cams-dbs true \
            --insecure-skip-tls-verify
    else
        echo "Invalid action: $ACTION" >&2
        exit 2
    fi
}

function delete_couchdb_route {
    oc delete route couchdb-route --ignore-not-found
}

if [ -z "$1" ]; then
    usage
fi

ACTION=$1

if [ "$ACTION" != "remove_dbs" ] && [ "$ACTION" != "list_dbs" ]; then
    echo "Error: Action must be either 'remove_dbs' or 'list_dbs'" >&2
    usage
fi

create_couchdb_route
run_cleanup
delete_couchdb_route
```

실행 (chmod +x 후):
```bash
${OC_LOGIN}
oc project ${PROJECT_CPD_INST_OPERANDS}
./cpd_catalog_api_post_migration_cleanup.sh list_dbs    # 삭제 대상 확인
./cpd_catalog_api_post_migration_cleanup.sh remove_dbs  # ★되돌릴 수 없음
./cpd_catalog_api_post_migration_cleanup.sh list_dbs    # 0 확인 (output should show 0 databases)
```

Parent topic: Setting up services after install or upgrade
