# 원문 — Updating the OpenShift CLI (5.1→5.3) `[2026-09-02 수집]`

경로: 5.3.x → Upgrading from Version 5.1 → Updating client workstations → **Updating the OpenShift CLI**
URL: https://www.ibm.com/docs/en/software-hub/5.3.x?topic=workstations-updating-openshift-cli [확정]
문서 갱신일: 2026-08-26

## 목차

- [우리 판정](#우리-판정)
- [본문 요지](#본문-요지)
- [9/10 정정 근거](#910-정정-근거)

## 우리 판정

> ★우리 판정:
> ```
> ① 요구사항은 "클러스터와 호환되는(compatible) oc 버전" — 특정 버전 강제 없음.
>    9/10 정정: 모비스는 OCP 4.18.13 유지이므로 oc·kubectl 4.18.13을
>    추가하여 기본 사용한다. 기존 oc 4.20.24는 보관용이다.
> ② oc-mirror는 별도 미러링 도구로 4.20.24를 유지한다.
>    oc까지 4.20.24 하나로 모두 호환된다는 기존 판단은 철회한다.
> ③ Managed OpenShift(ROSA·ARO 등) 표 — 모비스 self-managed → 해당 없음
> ```

## 본문 요지

Self-managed: Red Hat "Getting started with the OpenShift CLI" 문서로
설치 (버전 4.14/4.16/4.17/4.18/4.19/4.20/4.22 링크).
Managed(IBM Cloud Satellite·ROSA·ARO 등): 각 환경 문서 — 해당 없음.

## 9/10 정정 근거

- 계획서 특이사항 1: 이번 작업은 OCP 4.18.13 유지. 특정 z-stream 강제 규칙이라는 뜻이 아니라 현행 버전에 맞춘 우리 선택이다.
- [Red Hat 4.18 CLI 설치](https://docs.redhat.com/en/documentation/openshift_container_platform/4.18/html/cli_tools/openshift-cli-oc): 4.18용 Linux Clients 설치 안내 (2026-09-10 확인).
- [oc-mirror v2 문서](https://docs.redhat.com/en/documentation/openshift_container_platform/4.22/html/disconnected_environments/about-installing-oc-mirror-v2): 미러링 대상 OCP와 무관하게 최신 플러그인 사용을 권장한다. OCP가 4.18이라는 이유로 기존 4.20.24 미러링 도구를 낮추지는 않는다.
- [공식 체크섬 목록](https://mirror.openshift.com/pub/openshift-v4/x86_64/clients/ocp/4.18.13/sha256sum.txt): RHEL 8·9용 4.18.13 파일명을 2026-09-10 조회했다. 실제 파일 다운로드·현장 실행은 미확인이다.
- 적용: `현대/ibm/mobis2/scripts/3-down-tool.sh` 배치 A에 두 파일 추가, `export/scripts/0-setting/0-tools-install.sh`의 설치·PATH 출력·검증을 4.18.13으로 변경. 기존 4.20.24 파일은 삭제하지 않는다.
