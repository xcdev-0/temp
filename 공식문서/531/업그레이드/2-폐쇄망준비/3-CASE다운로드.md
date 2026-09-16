# 원문 — Downloading CASE packages ... in a restricted network (5.1→5.3) `[2026-09-02 수집]`

경로: 5.3.x → Upgrading from Version 5.1 → Preparing to run upgrades in a restricted network → **Downloading CASE packages**
URL: https://www.ibm.com/docs/en/software-hub/5.3.x?topic=pruirn-downloading-case-packages [확정]
문서 갱신일: 2026-07-15

> ★우리 판정:
> ```
> ① ★워크스페이스 이관 시 필수 3단계 발견 (Important) — CASE 를 다른 워크스테이션으로
>    옮기면: chown -R 1001 ./work → chmod -R 775 ./work → restart-container.
>    모비스 = 워크스페이스 통째 반입이므로 ★현장 반입 직후 이 3단계 필수
>    → 4-site-push 스크립트 olm 단계에 반영 [9/2 수정]
>    (1001 = olm-utils 컨테이너 내부 사용자 — 권한 안 맞으면 컨테이너가 work 를 못 읽음)
> ② CASE 다운로드 명령 = 우리 1번 스크립트 case 단계와 동일 (--patch_id 포함, GitHub/OCI 두 갈래)
> ③ CASE 가 필요해지는 후속 작업 목록 명시: 사설 레지스트리 준비·전제소프트웨어·
>    공유 컴포넌트·SWH 업그레이드 — 전부 워크스페이스의 CASE 를 전제
>    → p.50 전역 리소스도 이 CASE 재사용 가능성 ↑ [④-b 문서로 확정 예정]
> ```

## 본문 요지 + 명령

다운로드 (인터넷 워크스테이션 — 환경변수 source 후):
```bash
# GitHub
cpd-cli manage case-download \
--components=${COMPONENTS} \
--release=${VERSION} \
--patch_id=${PATCH_ID}
# OCI (icr.io): 위에 --from_oci=true 추가
```
결과: work 디렉토리에 CASE 저장.

★Important — CASE 를 다른 워크스테이션으로 이관하면 각 워크스테이션에서:
```bash
# work 를 품은 디렉토리에서
chown -R 1001 ./work
chmod -R 775 ./work
cpd-cli manage restart-container
```
