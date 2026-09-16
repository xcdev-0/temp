# 원문 — Pulling the olm-utils-v4 image from the private registry (5.1→5.3) `[2026-09-02 수집]`

경로: 5.3.x → Upgrading from Version 5.1 → Preparing to run upgrades from a private registry → **Pulling the olm-utils-v4 image**
URL: https://www.ibm.com/docs/en/software-hub/5.3.x?topic=prufpcr-pulling-olm-utils-v4-image-from-private-container-registry [확정]
문서 갱신일: 2026-08-20

> ★우리 판정:
> ```
> ① ★폐쇄망 최종형 확정 [4-환경변수.md 의 대조 대기 해소]:
>    export OLM_UTILS_IMAGE=${PRIVATE_REGISTRY_LOCATION}/cpopen/cpd/olm-utils-v4:${VERSION}.amd64
>    — 사설 주소에서도 아키 접미(.amd64) 포함이 정식.
>    런북 p.48(접미 없음)은 부정확 → env.sh 주석 갱신 [9/2]
> ② 시점: 사설로 미러 완료 후 + manage 명령 실행 전, 워크스테이션마다 1회
> ③ 이후 manage 명령은 사설에서 olm-utils 를 자동 pull — 별도 load 불필요
>    (tar load 방식은 2-폐쇄망준비 문서의 경로 — 사설에 올라가 있으면 이 방식이 더 단순)
> ④ 프리미엄 변형(경로 /cp/cpd/) — 모비스 해당 없음
> ```

## 본문 요지 + 명령 (x86-64)

전제: 사설 미러 완료 + cpd-cli 설치.
환경변수 스크립트의 OLM_UTILS_IMAGE 를 사설 주소로 (없으면 추가):
```bash
export OLM_UTILS_IMAGE=${PRIVATE_REGISTRY_LOCATION}/cpopen/cpd/olm-utils-v4:${VERSION}.amd64
```
결과: manage 명령 실행 시 사설 레지스트리에서 자동 pull.
