# 원문 — Upgrading the IBM Events Operator for wxA/wxO (5.1→5.3) `[2026-09-02 수집]`

경로: 5.3.x → Upgrading from Version 5.1 → Preparing to upgrade an instance → **Upgrading the IBM Events Operator**
URL: [미확인 — 주소 받으면 기입]
문서 갱신일: 2026-07-15

> ★우리 판정:
> ```
> ① 모비스 해당 없음 확정 [본문 재확인] — 조건이 이중:
>    (a)5.3.1+ 로 갈 때만 + (b)wx Assistant 또는 wx Orchestrate 설치 시만.
>    모비스는 (b) 불충족 → 통째 건너뜀. 런북 누락 아님 최종 확정
> ② (참고) ★삼성 랩엔 유관 — 삼성은 wxo 설치본이라, 삼성 5.4 업그레이드
>    시나리오에선 이 절(deploy-events-operator)이 등장할 수 있음.
>    선행조건: Serverless Knative Eventing 업그레이드
> ```

## 본문 요지 + 명령 (참고 보존 — 삼성용)

조건: 5.3.1+ 업그레이드 + wxA/wxO 설치 인스턴스.
선행: Upgrading Red Hat OpenShift Serverless Knative Eventing.
```bash
${CPDM_OC_LOGIN}
cpd-cli manage deploy-events-operator \
--release=${VERSION} \
--events_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--events_operand_ns=${PROJECT_CPD_INST_OPERANDS}
```
