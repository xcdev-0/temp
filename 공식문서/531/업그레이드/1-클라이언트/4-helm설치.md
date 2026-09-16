# 원문 — Installing the Helm CLI (5.1→5.3) `[2026-09-02 수집]`

경로: 5.3.x → Upgrading from Version 5.1 → Updating client workstations → **Installing the Helm CLI**
URL: https://www.ibm.com/docs/en/software-hub/5.3.x?topic=workstations-installing-helm-cli [확정]
문서 갱신일: 2026-07-15

> ★우리 판정:
> ```
> ① "선택이지만 권장" 확정 — 런북 p.13 "(선택)" 표기와 일치. 우리 tools 에 3.19.0 확보 ✓
> ② 용도가 구체적으로 명시됨 [수확]:
>    - 클러스터 관리자: case-download(--cluster_resources)·apply-scheduler·
>      setup-control-center 디버깅 ← ★--cluster_resources 가 여기 등장 —
>      p.50 전역 리소스 작업에서 문제 나면 helm 으로 디버깅한다는 것
>    - 인스턴스 관리자: install-components·uninstall-components 디버깅
> ③ 없으면 olm-utils 컨테이너 안에 exec 해서 디버깅해야 — helm 지참이 편한 이유
> ```

## 본문 요지

Install the Helm CLI (optional but recommended) — Helm 에 의존하는
cpd-cli 명령의 이슈 디버깅을 쉽게 한다. 설치는 Helm 공식 문서.
없으면 olm-utils-v4 컨테이너에 exec 해서 디버깅해야 한다.
