# 원문 — Reauthorizing the NamespaceScope operator (min RBAC) (5.1→5.3) `[2026-09-02 수집]`

경로: 5.3.x → Upgrading from Version 5.1 → Preparing to upgrade an instance → **Reauthorizing the NamespaceScope operator**
URL: [미확인 — 주소 받으면 기입]
문서 갱신일: 2026-08-20

> ★우리 판정:
> ```
> ① jq 확인 명령 = 런북 p.52 와 동일 [일치]. true → 스킵 / false → 재인증 필요.
>    (authorize-instance-topology 로 설치한 경우도 스킵)
> ② ★런북엔 "follow the doc" 링크뿐이던 false 대응 절차 전문 확보:
>    show-minimum-rbac 로 role yaml 생성 → 오퍼레이터·오퍼랜드 NS 에 role apply
>    → 같은 이름 RoleBinding 생성(SA=ibm-namespace-scope-operator).
>    현장에서 false 나와도 이제 막히지 않음
> ③ 테더드 변형 존재 — 모비스 해당 없음
> ④ 모비스 실측: jq 명령 결과 true/false 가 이 절 실행 여부를 결정
> ```

## 본문 요지 + 명령

판별 (런북 p.52 와 동일):
```bash
oc get role nss-managed-role-from-${PROJECT_CPD_INST_OPERATORS} \
-n ${PROJECT_CPD_INST_OPERATORS} \
-o json | jq 'any(.rules[].apiGroups[]; . == "*")'
# true = 재인증 불필요 / false = 아래 절차 실행
```

false 일 때 (★런북에 없던 실제 절차):
```bash
${CPDM_OC_LOGIN}
# ① 최소 RBAC role yaml 생성 (work 디렉토리에 생성됨)
cpd-cli manage show-minimum-rbac \
--cpd_operator_ns=${PROJECT_CPD_INST_OPERATORS} \
--components=${COMPONENTS} \
--release=${VERSION} \
--patch_id=${PATCH_ID}
# ② role 을 두 NS 에 적용
oc apply -f nss-managed-role-from-${PROJECT_CPD_INST_OPERATORS}.yaml --namespace=${PROJECT_CPD_INST_OPERATORS}
oc apply -f nss-managed-role-from-${PROJECT_CPD_INST_OPERATORS}.yaml --namespace=${PROJECT_CPD_INST_OPERANDS}
# ③ RoleBinding 생성 — 두 NS 각각 (heredoc, SA=ibm-namespace-scope-operator,
#    roleRef=위 role. 전문은 원문 — 테더드 변형은 모비스 무관)
```
