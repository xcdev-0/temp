# 원문 — Updating the IBM Software Hub CLI (5.1→5.3) `[2026-09-02 수집]`

경로: 5.3.x → Upgrading from Version 5.1 → Updating client workstations → **Updating the IBM Software Hub CLI**
URL: https://www.ibm.com/docs/en/software-hub/5.3.x?topic=workstations-updating-software-hub-cli [확정]
문서 갱신일: 2026-08-20

> ★우리 판정:
> ```
> ① ★현장 절차 발견 — "옛 cpd-cli 설치본의 cpd-cli-workspace 디렉토리를 새 14.3.1 설치본으로
>    복사하라"(Important) + work 하위 디렉토리 전원 rwx(0777) 확인.
>    → 모비스 현장에서 14.1.3→14.3.1 전환 시 해야 할 일. 단 우리는 CPD_CLI_MANAGE_WORKSPACE
>    로 워크스페이스를 명시 지정하므로 복사 대신 변수 지정으로 갈음 가능 [우리 방식 유지]
> ② "옛 설치본 삭제" 권고 — ⚠모비스는 백업(5.1.3 국면)에 14.1.3 이 다시 필요하므로 삭제하지
>    않는다. 문서는 단일 교체 시나리오 — 우리 버전별 폴더 전략(cli-v14.x.x/)이 안전한 이유
> ③ CPD_CLI_MANAGE_WORKSPACE 공식 정의 확보 [확정] — 기본값 없음, 실행 위치 기준 생성,
>    변수로 고정 가능. 우리 3-down.sh·1번 스크립트 방식의 정본 근거
> ④ OLM_UTILS_LAUNCH_ARGS — 프록시로 미러/CASE 받을 땐 CA 마운트 필수(Important).
>    env.sh 주석에 이미 반영돼 있음 ✓. K8s 인증서 마운트 변형도 있음
> ⑤ 기본은 olm-utils-v4 를 Entitled Registry 에서 자동 pull — OLM_UTILS_IMAGE 재정의는
>    프리미엄 라이선스(olm-utils-premium-v4) 경우. 모비스 = 표준 → 재정의는 폐쇄망 주소용만
> ⑥ 확인 명령: cpd-cli manage restart-container (버전 확인 겸)
> ```

## Procedure (요지 + 명령)

1. GitHub IBM/cpd-cli 에서 14.3.1 다운로드 — OS·아키·에디션별 표
   (모비스: Linux x86_64 EE = cpd-cli-linux-EE-14.3.1.tgz ✓확보됨)
2. 원하는 실행 위치에 풀기
3. ★옛 설치본의 cpd-cli-workspace 를 새 설치본 옆으로 복사 (Important:
   cpd-cli 실행파일과 같은 디렉토리에) + work 권한 확인:
```bash
ls -l          # drwxrwxrwx 아니면:
chmod 0777 ./work
```
4. 옛 설치본 삭제 (⚠모비스: 14.1.3 은 백업용으로 유지 — 판정 ②)
5. (Mac 전용 신뢰 설정 — 해당 없음)
6. Best practice: PATH 등록 (~/.bashrc 에 export PATH=<경로>:$PATH)
7. Best practice: 환경변수 검토
```bash
# 워크스페이스 고정 (기본값 없음 — 실행 위치 기준 생성)
export CPD_CLI_MANAGE_WORKSPACE=<fully-qualified-directory>
# 프록시/자체서명 CA (미러·CASE 다운로드에 프록시 쓰면 필수)
export OLM_UTILS_LAUNCH_ARGS=" -v /etc/pki/ca-trust:/etc/pki/ca-trust"
# K8s API 인증서: " -v <k8-loc>:/etc/k8scert --env K8S_AUTH_SSL_CA_CERT=/etc/k8scert"
```
   Important: 설정했으면 환경변수 스크립트에도 추가
8. 확인:
```bash
cpd-cli manage restart-container
```
