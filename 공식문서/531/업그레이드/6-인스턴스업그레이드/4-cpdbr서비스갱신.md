# 원문 — Updating the cpdbr service (5.1→5.3) `[2026-09-02 수집]`

경로: 5.3.x → Upgrading from Version 5.1 → Upgrading an instance → **Updating the cpdbr service**
URL: [미확인 — 주소 받으면 기입]
문서 갱신일: 2026-08-20

> ★우리 판정 (런북 p.68·B10 의 원본 — 대조 결과):
> ```
> ① ★B10 뿌리 확정 — 원문은 백업 도구 4갈래(OADP/Fusion/NetApp/Portworx) 분기 구조.
>    OADP_OPERATOR_NS export 단계는 ★NetApp·Portworx 갈래에만 있고 OADP 갈래엔 없음.
>    런북 p.68 은 NetApp/Portworx 갈래의 export 문장 + OADP 갈래 명령을 짜깁기한 것 —
>    "NetApp/Portworx 쓰면 설정하라"는 조건문이 그래서 생긴 것. B10 처방(무조건 지정) 유지
> ② ★런북 p.68 과 명령 차이 발견 — 공식 OADP 갈래 플래그:
>    --cpfs-image-version=latest 가 있음 (런북엔 없음) /
>    런북의 --cpdbr-hooks-image-prefix·--cpfs-image-prefix (사설 주소 지정) 는
>    공식 5.3.x OADP 갈래에 없음 — 폐쇄망이므로 런북식 prefix 지정이 실용적일 수
>    있으나 [잠정] 실행판은 두 판 대조 후 결정 (5.1.x 설치구성 §3.3 은 prefix 방식)
> ③ ★스케줄러 변형 존재: --cpd-scheduler-namespace=${PROJECT_SCHEDULING_SERVICE} 추가
>    — 스케줄러 조건부 4번째 항목 (3종 세트 → 4종: 전역리소스·NS시크릿·apply-scheduler·
>    cpdbr-tenant 의 스케줄러 플래그). ⚠원문 표기 오류: 두 변형 제목이 둘 다
>    "Environments with the scheduling service" — 두 번째는 without 이 맞음 (명령 내용으로 판별)
> ④ Fusion/NetApp/Portworx 갈래 — 모비스 OADP → 해당 없음 (Fusion 갈래의 DPA 플러그인
>    스크립트는 참고 가치: cpfs-oadp-plugin·db2u·swhub 3종 add_plugin_if_missing 패턴)
> ⑤ 시점 확정: "SWH 업그레이드 후" — 런북 p.68 위치(Post Upgrade) 정당성 확인
> ```

## 본문 요지 + 명령 (OADP 갈래 — 모비스 해당)

시점: SWH(5.3.1) 업그레이드 후. 클러스터 관리자.

스케줄러 있는 환경:
```bash
cpd-cli oadp install \
--component=cpdbr-tenant \
--namespace=${OADP_OPERATOR_NS} \
--tenant-operator-namespace=${PROJECT_CPD_INST_OPERATORS} \
--cpd-scheduler-namespace=${PROJECT_SCHEDULING_SERVICE} \
--cpfs-image-version=latest \
--skip-recipes=true \
--upgrade=true \
--log-level=debug \
--verbose
```
스케줄러 없는 환경 (⚠원문 제목 오타 — 내용상 without):
```bash
cpd-cli oadp install \
--component=cpdbr-tenant \
--namespace=${OADP_OPERATOR_NS} \
--tenant-operator-namespace=${PROJECT_CPD_INST_OPERATORS} \
--cpfs-image-version=latest \
--skip-recipes=true \
--upgrade=true \
--log-level=debug \
--verbose
```
※ OADP_OPERATOR_NS: 원문 OADP 갈래엔 export 단계가 없으나 명령이 참조 —
  B10 처방대로 무조건 export OADP_OPERATOR_NS=oadp-operator 선행 (env.sh 반영됨)
※ 런북 p.68 은 --cpdbr-hooks-image-prefix=<사설>/cpopen/cpd
  --cpfs-image-prefix=<사설>/cpopen/cpfs 방식 — 폐쇄망 이미지 주소 지정.
  실행판 결정 [잠정]: 사설 레지스트리이므로 prefix 방식(런북·5.1.x §3.3 계열)
  우선, --cpfs-image-version=latest 는 :latest 폐쇄망 위험(C2 유사) 검토

(참고 — Fusion 갈래에만 있는 것: velero 파드 ephemeral-storage 2Gi/메모리 4Gi
 패치 + add_plugin_if_missing 스크립트로 cpfs-oadp/db2u/swhub 플러그인 정합화)
