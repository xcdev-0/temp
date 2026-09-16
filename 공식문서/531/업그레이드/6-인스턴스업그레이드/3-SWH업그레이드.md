# 원문 — Upgrading IBM Software Hub (5.1→5.3) `[9/2 수집 → 9/3 전문 승격]`

경로: 5.3.x → Upgrading from Version 5.1 →
Upgrading an instance → **Upgrading IBM Software Hub**
URL: [https://www.ibm.com/docs/en/software-hub/5.3.x?topic=uish-upgrading-software-hub](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=hub-upgrading-software)
문서 갱신일: 2026-08-20
※9/2 요약 저장분을 9/3 사용자 재붙여넣기로 전문 교체
  (접힌 블록 제외 — 아래 [접힘] 표기)

> ★우리 판정 (런북 p.53~60 의 원본 — 대조 결과):
> ```
> ① 뼈대 일치 [대조]: global search 체크 → catalog-api 체크·DB 수 세기(curl+TOKEN)
>    → 다운타임 표(6/20/60분) → precheck_migration.sh 전문(줄까지 동일) →
>    판정표 → install-components cpd_platform → RSI 패치 → get-cr-status →
>    health operators/operands. 런북이 이 페이지의 충실한 사본이었음
> ② ★런북에 없는 것 5건 수확:
>    (a) --preview=true 팁 — 실행 전 oc 명령 미리보기(work/preview.sh 저장).
>        ★PROD 첫 실행 전 안전장치로 실행판 채택 가치 높음
>    (b) --run_storage_tests 해설 — 스토리지 최소 성능 검사. 강력 권장,
>        미달 시 옵션 제거로 진행 가능하나 문제 가능성 경고 (런북은 플래그만 있음)
>    (c) ★배치 업그레이드 선택지 — cpd_platform 만 먼저 올린 뒤,
>        --components=${COMPONENTS} 로 서비스 전체를 한 방에 올리는
>        install-components 변형(Optional). 런북의 서비스 도미노(p.61~64
>        하나씩 6번)를 이 한 명령으로 대체 가능 — 실행판 선택지
>    (d) health operators/operands 의 기대 결과 표 전문 (SUCCESS/SKIP 기준)
>    (e) [9/3 전문에서 추가 확보] 반자동 활성화 patch 명령 —
>        use_semi_auto_catalog_api_migration: true (판정표 3행)
> ③ 서비스별 선행(wxA 소유권 이전·Ansible isvc 삭제) — 모비스 해당 없음
> ④ [9/3 확정] 스텝3 본 명령(tethered 없음 판) 공개 — 런북 p.59·체크리스트
>    No.110 과 일치 확인: --components=cpd_platform +
>    --run_storage_tests=true + --upgrade=true (아래 전문).
>    tethered 있음 판만 접힘 잔존(모비스 해당 없음)
>    + Db2 라이선스 변형(DB2SE/DB2AE) 명령도 공개
>    ※precheck_migration.sh 는 export/scripts/ 에 반출 배치 [9/3]
> ⑤ 모비스 예상: couchdb PVC 30Gi + scaleConfig 미설정(=small)
>    → "ready ... as usual" = 자동 이사 예상 [체크리스트 No.69 일치]
> ```

---

## 원문 전문

Upgrading IBM Software Hub
(Upgrading from Version 5.1 to Version 5.3)
Last Updated: 2026-08-20

To upgrade an instance of IBM Software Hub, you must grade
the required operators and custom resources for the
instance.

Upgrade phase:
- You are not here. Collecting required information
- You are not here. Updating your client workstation
- You are not here. Preparing to run an upgrade in a
  restricted network
- You are not here. Preparing to run an upgrade from a
  private container registry
- You are not here. Upgrading prerequisite software
- You are not here. Upgrading shared cluster components
- You are not here. Preparing to upgrade an instance
- **You are here icon. Upgrading an instance**

Who needs to complete this task?
- Instance administrator — An instance administrator can
  complete this task.

When do you need to complete this task?
- Repeat as needed — If you have multiple instances of IBM
  Software Hub on the cluster, complete this task for each
  instance that you want to upgrade.

### Before you begin

Best practice: You can run the commands in this task
exactly as written using the installation environment
variables. Ensure that you added the new environment
variables from Updating your environment variables script.

In addition, ensure that you source the environment
variables before you run the commands in this task.

**Service-specific prerequisite tasks**

If you have any of the following services on this instance
of IBM Software Hub, complete the required steps before
you upgrade IBM Software Hub (둘 다 모비스 해당 없음):
- watsonx Assistant: "Transfer ownership of the ..."
  [일부만 노출 — 원문 문장 잘림]
- watsonx Code Assistant for Red Hat Ansible Lightspeed:
  Delete the ibm-granite-3b-code-v1 and
  ibm-granite-20b-code-8k-ansible InferenceService object:
```bash
oc delete isvc ibm-granite-3b-code-v1 ibm-granite-20b-code-8k-ansible \
-n ${PROJECT_CPD_INST_OPERANDS} \
--ignore-not-found
```

**Common core services**

Before you upgrade IBM Software Hub, check for the whether
the following pods are running in this instance of IBM
Software Hub:

a. Check whether the global search pods are running:
```bash
oc get pods --namespace=${PROJECT_CPD_INST_OPERANDS} | grep elasticsea-0ac3
```
- If the command returns an empty response, proceed to the
  next step.
- If the command returns a list of pods, review "Upgrades
  fail when global search is configured incorrectly" to
  determine whether you have any configurations that could
  cause issues during upgrade.
https://www.ibm.com/docs/en/software-hub/5.3.x?topic=tiu-upgrades-fail-when-global-search-is-configured-incorrectly
b. Check whether the catalog-api pods are running:
```bash
oc get pods --namespace=${PROJECT_CPD_INST_OPERANDS} | grep catalog-api
```
- If the command returns an empty response, you are ready
  to upgrade IBM Software Hub.
- If the command returns a list of pods, review the
  following guidance to determine how long the catalog-api
  service will be down during upgrade.

When you upgrade the common core services to IBM Software
Hub Version 5.3, the underlying storage for the
catalog-api service is migrated to PostgreSQL.

During the final stages of the migration, the catalog-api
service is offline, and services that are dependent on the
service are not available. The duration of the migration
depends on the number of assets and relationships that are
stored in the instance. The duration of the outage depends
on the number of databases (projects, catalogs, and
spaces) in the instance. In a typical upgrade scenario,
the outage should be significantly shorter than the
overall migration.

To determine how many databases will be migrated:

1. Set the INSTANCE_URL environment variable to the URL of
   IBM Software Hub:
```bash
export INSTANCE_URL=<URL>
```
   Tip: To get the URL of the web client, run the
   following command:
```bash
cpd-cli manage get-cpd-instance-details \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

2. Get the credentials for the wdp-service:
```bash
TOKEN=$(oc get -n ${PROJECT_CPD_INST_OPERANDS} secrets wdp-service-id -o yaml | grep service-id-credentials | cut -d':' -f2- | sed -e 's/ //g' | base64 -d)
```

3. Get the number of catalogs in the instance:
```bash
curl -sk -X GET "https://${INSTANCE_URL}/v2/catalogs?limit=10001&skip=0&include=catalogs&bss_account_id=999" -H 'accept: application/json' -H "Authorization: Basic ${TOKEN}" | jq -r '.catalogs | length'
```

4. Get the number of projects in the instance:
```bash
curl -sk -X GET "https://${INSTANCE_URL}/v2/catalogs?limit=10001&skip=0&include=projects&bss_account_id=999" -H 'accept: application/json' -H "Authorization: Basic ${TOKEN}" | jq -r '.catalogs | length'
```

5. Get the number of spaces in the instance:
```bash
curl -sk -X GET "https://${INSTANCE_URL}/v2/catalogs?limit=10001&skip=0&include=spaces&bss_account_id=999" -H 'accept: application/json' -H "Authorization: Basic ${TOKEN}" | jq -r '.catalogs | length'
```

f. Add up the number of catalogs, projects, and spaces
returned by the previous commands. Then, use the following
table to determine approximately how long the service will
be offline during the migration:

| Databases | Downtime for migration (approximate) |
|---|---|
| Up to 1,000 databases | 6 minutes |
| 1,001 - 10,000 databases | 20 minutes |
| 10,001 - 70,000 databases | 60 minutes |

g. Save the following script on the client workstation as
a file named precheck_migration.sh:

```bash
#!/bin/bash

# Default ranges for couchdb size
SMALL=50
MEDIUM=100
LARGE=200

echo "Performing pre-migration checks"

patch_for_small()
{
  echo -e "Run the following command to increase the CPU and memory:\n"
          cat << EOF
oc patch ccs ccs-cr -n ${PROJECT_CPD_INST_OPERANDS} --type merge --patch '{"spec": {
  "catalog_api_postgres_migration_threads": 4,
  "catalog_api_migration_job_resources": { 
    "requests": {"cpu": "2", "ephemeral-storage": "10Mi", "memory": "2Gi"},
    "limits": {"cpu": "6", "ephemeral-storage": "1Gi", "memory": "6Gi"}}
}}'
EOF
    echo
    echo "The system is ready for migration. Upgrade your cluster as usual."
}

patch_for_medium()
{
    echo -e "Run the following command to increase the CPU and memory:\n"
          cat << EOF
oc patch ccs ccs-cr -n ${PROJECT_CPD_INST_OPERANDS} --type merge --patch '{"spec": {
  "catalog_api_postgres_migration_threads": 6,
  "catalog_api_migration_job_resources": { 
    "requests": {"cpu": "3", "ephemeral-storage": "10Mi", "memory": "4Gi"},
    "limits": {"cpu": "8", "ephemeral-storage": "4Gi", "memory": "8Gi"}}
}}'
EOF
    echo
    echo "The system is ready for migration. Upgrade your cluster as usual."
}

patch_for_large()
{
    echo -e "Run the following command to increase the CPU and memory:\n"
          cat << EOF
oc patch ccs ccs-cr -n ${PROJECT_CPD_INST_OPERANDS} --type merge --patch '{"spec": {
  "catalog_api_postgres_migration_threads": 8,
  "catalog_api_migration_job_resources": { 
    "requests": {"cpu": "6", "ephemeral-storage": "10Mi", "memory": "6Gi"},
    "limits": {"cpu": "10", "ephemeral-storage": "6Gi", "memory": "10Gi"}}
}}'
EOF
    echo
    echo "Before you can start the upgrade, you must prepare the system for migration."
}

check_resources(){
        scale_config=$1
        pvc_size=$(oc get pvc -n ${PROJECT_CPD_INST_OPERANDS} database-storage-wdp-couchdb-0 --no-headers | awk '{print $4}')
        size=$(awk '{print substr($0, 1, length($0)-2)}' <<< "$pvc_size")

        if [[ $scale_config == "small" ]];then
          if [[ "$size" -le "$SMALL" ]];then
            echo "The system is ready for migration. Upgrade your cluster as usual."
          elif [ "$size" -ge "$SMALL" ] && [ "$size" -le "$MEDIUM" ];then
            patch_for_medium
          elif [ "$size" -ge "$MEDIUM" ] && [ "$size" -le "$LARGE" ];then
            patch_for_large
          else
            patch_for_large
          fi
        elif [[ $scale_config == "medium" ]];then
          if [[ "$size" -le "$SMALL" ]];then
            patch_for_small
          elif [ "$size" -ge "$SMALL" ] && [ "$size" -le "$MEDIUM" ];then
            echo "The system is ready for migration. Upgrade your cluster as usual."
          elif [ "$size" -ge "$MEDIUM" ] && [ "$size" -le "$LARGE" ];then
            patch_for_large
          else
            patch_for_large
          fi
        elif [[ $scale_config == "large" ]];then
          if [[ "$size" -le "$SMALL" ]];then
            patch_for_small
          elif [ "$size" -ge "$SMALL" ] && [ "$size" -le "$MEDIUM" ];then
            patch_for_medium
          elif [ "$size" -ge "$MEDIUM" ] && [ "$size" -le "$LARGE" ];then
            echo "The system is ready for migration. Upgrade your cluster as usual."
          else
            patch_for_large
          fi
        fi
}

check_upgrade_case(){     
        echo -e "Checking if automatic upgrade or semi-automatic upgrade is needed"
        scale_config=$(oc get ccs -n ${PROJECT_CPD_INST_OPERANDS} ccs-cr -o json | jq -r '.spec.scaleConfig')

        # Default case, scale config is set to small
        if [[ -z "${scale_config}" ]];then
          scale_config=small
        fi

        check_resources $scale_config
}

check_upgrade_case
```

h. Run the precheck_migration.sh to determine whether you
can run an automatic migration of the common core services
or whether you need to configure common core services to
run a semi-automatic migration:
```bash
./precheck_migration.sh
```

Take the appropriate action based on the message returned
by the script:

| Messages returned by the script | Migration type | What to do next |
|---|---|---|
| The system is ready for migration. Upgrade your cluster as usual. | Automatic | You are ready to upgrade IBM Software Hub. Important: After you upgrade the services in your environment, ensure that you complete Completing the catalog-api service migration |
| Run the following command to increase the CPU and memory. | Automatic | 1. Run the patch command returned by the script. 2. Upgrade IBM Software Hub. Important: After you upgrade the services in your environment, ensure that you complete Completing the catalog-api service migration |
| The script returns both of the following messages: "Run the following command to increase the CPU and memory." + "Before you can start the upgrade, you must prepare the system for migration." | Semi-automatic | 1. Run the patch command returned by the script. 2. Run the following command to enable semi-automatic migration (아래 명령). 3. Upgrade IBM Software Hub. Important: After you upgrade the services in your environment, ensure that you complete Completing the catalog-api service migration |

반자동 활성화 명령 (판정표 3행의 것):
```bash
oc patch ccs ccs-cr \
-n ${PROJECT_CPD_INST_OPERANDS} \
--type merge \
--patch '{"spec": {"use_semi_auto_catalog_api_migration": true}}'
```

### About this task

Use the cpd-cli manage install-components command to
upgrade the required operators and custom resources for an
instance of IBM Software Hub.

Note: The install-components command in this topic
includes the --run_storage_tests option. It is strongly
recommended that you run the command with the
--run_storage_tests option to enure that the storage in
your environment meets the minimum requirements for
performance.

If your storage does not meet the minimum requirements,
you can remove the --run_storage_tests option to continue
the upgrade. However, your environment is likely to
encounter problems because of issues with your storage.

### Procedure

1. Log the cpd-cli in to the Red Hat OpenShift Container
   Platform cluster:
```bash
${CPDM_OC_LOGIN}
```
   Remember: CPDM_OC_LOGIN is an alias for the
   cpd-cli manage login-to-ocp command.

2. Review the license terms for the software that you plan
   to install. The licenses are available online. However,
   some licenses are not included in the get-license
   command. If you don't see the license that you
   purchased, you can search for the license on IBM Terms.

   See all available license URLs:
```bash
cpd-cli manage get-license \
--release=${VERSION}
```
   See the URL for a specific license — run the
   appropriate commands based on the license or licenses
   that you purchased (Db2 만 9/3 노출, 나머지 접힘):
   IBM Cloud Pak for Data Enterprise Edition /
   IBM Cloud Pak for Data Standard Edition /
   IBM Data Gate for watsonx / IBM Data Product Hub
   Cartridge / Data Replication / Db2 /
   IBM Knowledge Catalog Premium / IBM Knowledge Catalog
   Standard / IBM watsonx.ai / IBM watsonx Code Assistant /
   IBM watsonx Code Assistant for Ansible /
   IBM watsonx.data / IBM watsonx.data Premium Edition

   Db2 — run the appropriate command based on the license
   that you purchased:
   IBM Db2 Standard Edition Cartridge for IBM Cloud Pak
   for Data:
```bash
cpd-cli manage get-license \
--release=${VERSION} \
--license_types=DB2SE
```
   IBM Db2 Advanced Edition Cartridge for IBM Cloud Pak
   for Data:
```bash
cpd-cli manage get-license \
--release=${VERSION} \
--license_types=DB2AE
```

3. Upgrade the required operators and custom resources for
   the instance.
   Tip: Before you run this command against your cluster,
   you can preview the oc commands that this command will
   issue on your behalf by running the command with the
   --preview=true option. The oc commands are saved to the
   preview.sh file in the work directory.
   The command that you run depends on whether the
   instance includes tethered projects:

   Instances without tethered projects
   (★모비스 = 이 변형. 런북 p.59·체크리스트 No.110 일치):
```bash
cpd-cli manage install-components \
--license_acceptance=true \
--components=cpd_platform \
--release=${VERSION} \
--patch_id=${PATCH_ID} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--image_pull_prefix=${IMAGE_PULL_PREFIX} \
--image_pull_secret=${IMAGE_PULL_SECRET} \
--run_storage_tests=true \
--upgrade=true
```
   Instances with tethered projects [접힘 미노출 —
   모비스 해당 없음]

4. Wait for the cpd-cli to return the following message
   before preceding to the next step:
```
[SUCCESS] ... The install-components command ran successfully.
```

5. If you have any custom RSI patches that patch zen pods
   or IBM Cloud Pak foundational services pods, reapply
   the patches:
   a. Run the following command to get a list of the RSI
      patches in the operands project:
```bash
cpd-cli manage get-rsi-patch-info \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--all
```
   b. If there are patches that apply to zen or IBM Cloud
      Pak foundational services pods, run the following
      command to apply your custom patches:
```bash
cpd-cli manage apply-rsi-patches \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

6. Optional: If you want to run a batch upgrade of the
   services that are installed on the instance, run the
   install-components command.
   Tip: --preview=true 미리보기 가능 (work/preview.sh).
```bash
cpd-cli manage install-components \
--license_acceptance=true \
--components=${COMPONENTS} \
--release=${VERSION} \
--patch_id=${PATCH_ID} \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--instance_ns=${PROJECT_CPD_INST_OPERANDS} \
--image_pull_prefix=${IMAGE_PULL_PREFIX} \
--image_pull_secret=${IMAGE_PULL_SECRET} \
--upgrade=true
```
   Wait for the cpd-cli to return the following message
   before preceding to the next step:
```
[SUCCESS] ... The install-components command ran successfully.
```

7. Confirm that the status of the operands is Completed:
```bash
cpd-cli manage get-cr-status \
--cpd_instance_ns=${PROJECT_CPD_INST_OPERANDS}
```

8. Check the health of the resources in the operators
   project:
```bash
cpd-cli health operators \
--operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--control_plane_ns=${PROJECT_CPD_INST_OPERANDS}
```

   Confirm that the health check report returns the
   expected results:

| Test | What the test checks | Expected result |
|---|---|---|
| Pod Healthcheck | For pods in the operators project, the status of each required pod is Running. | [SUCCESS] |
| Pod Usage Healthcheck | For pods in the operators project, the resource use for each pod is within the CPU and memory limits. | [SUCCESS] |
| Cluster Service Versions Healthcheck | For cluster service versions (CSVs) in the operators project, the phase of each CSV is Succeeded. | [SUCCESS] |
| Catalog Source Healthcheck | For catalog sources in the operators project, the last observed state of each catalog source is Ready. | [SUCCESS] |
| Install Plan Healthcheck | For operators in the operators project, the install plan approval for each operator is Automatic. | [SUCCESS] |
| Subscriptions Healthchec | For subscriptions in the operators project, there is an installed CSV for each subscription. | [SUCCESS] |
| Persistent Volume Claim Healthcheck | For persistent volume claims (PVCs) in the operators project, each PVC is bound. Note: There should not be any PVC in the operators project, so the test should be skipped. | [SKIP...] |
| Deployment Healthcheck | For deployments in the operators project, each deployment has the desired number of replicas. | [SUCCESS] |
| Namespace Scopes Healthcheck | For the NamespaceScope operator in the operators project, the projects that are specified in the members list exist. | [SUCCESS] |
| Stateful Set Healthcheck | For stateful sets in the operators project, the stateful sets have the desired number of replicas. Note: There should not be any stateful sets in the operators project, so the test should be skipped. | [SKIP...] |
| Common Services Healthcheck | For the common-service commonservice custom resource in the operators project, the phase of the custom resource is Succeeded. | [SUCCESS] |
| Custom Resource Healthcheck | For any other custom resources in the operators project, the phase of each custom resource is Succeeded. Note: There should not be any other custom resources in the operators project, so the test should be skipped. | [SKIP...] |
| Operand Requests Healthcheck | For operand requests in the operators project, the phase of each operand request is Running, | [SUCCESS] |

9. Check the health of the resources in the operands
   project:
```bash
cpd-cli health operands \
--control_plane_ns=${PROJECT_CPD_INST_OPERANDS}
```

   Confirm that the health check report returns the
   expected results:

| Test | What the test checks | Expected result |
|---|---|---|
| Pod Healthcheck | For pods in the operands project, the status of each pod is Running. | [SUCCESS] |
| Pod Usage Healthcheck | For pods in the operands project, the resource use for each pod is within the CPU and memory limits. | [SUCCESS] |
| EDB Cluster Healthcheck | For EDB Postgres clusters in the operands project, the status of each cluster is Cluster in healthy state. | [SUCCESS] |
| Persistent Volume Claim Healthcheck | For persistent volume claims (PVCs) in the operands project, each PVC is bound. | [SUCCESS] |
| Deployment Healthcheck | For deployments in the operands project, each deployment has the desired number of replicas. | [SUCCESS] |
| Stateful Set Healthcheck | For stateful sets in the operands project, the stateful sets have the desired number of replicas. | [SUCCESS] |
| Common Services Healthcheck | For the common-service commonservice custom resource in the operands project, the phase of the custom resource is Succeeded. | [SUCCESS] |
| Operand Requests Healthcheck | For operand requests in the operands project, the phase of each operand request is Running. | [SUCCESS] |
| Monitor Events Healthcheck | The platform monitors are not generating any Critical events. | [SUCCESS] |
| Custom Resource Healthcheck | For custom resources in the operands project, the phase of each custom resource is Succeeded. | [SUCCESS] |
| Platform Healthcheck | That the pods for required platform microservices are Running. | [SUCCESS] |

### What to do next

Now that you've upgraded the IBM Software Hub control
plane, you're ready to complete Updating the cpdbr service
(Upgrading from Version 5.1 to Version 5.3).

If you don't use the cpdbr service, see Upgrading the IBM
Software Hub configuration admission controller webhook
(Upgrading from Version 5.1 to Version 5.3).

Parent topic: Upgrading an instance of IBM Software Hub
Previous topic: Creating image pull secrets for an
instance of IBM Software Hub
Next topic: Updating the cpdbr service

Related reference: cpd-cli manage login-to-ocp /
get-license / setup-instance / apply-olm / apply-cr /
get-cr-status
