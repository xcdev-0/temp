# 원문 — Obtaining the olm-utils-v4 image ... in a restricted network (5.1→5.3) `[2026-09-02 수집]`

경로: 5.3.x → Upgrading from Version 5.1 → Preparing to run upgrades in a restricted network → **Obtaining the olm-utils-v4 image**
URL: [미확인 — 주소 받으면 기입]
문서 갱신일: 2026-08-20

> ★우리 판정:
> ```
> ① 시나리오 두 갈래: (a)같은 워크스테이션을 안으로 반입 → restart-container 로 미리 pull
>    (b)★다른 워크스테이션 — 모비스 방식: save-image → tar 전송 → load-image → OLM_UTILS_IMAGE
> ② ★접미 확정 [5.3.x 공식]: save-image·load-image·OLM_UTILS_IMAGE 전부
>    ${VERSION}.amd64 접미 포함. 런북 p.36 의 접미 없는 :$VERSION 은 구식/부정확 표기
>    → 4-site-push 스크립트 olm 단계 접미 반영 [9/2 수정]
> ③ ★문서 자체의 파일명 오락가락 발견: amd64 절만 "icr.io_cpd_olm-utils-v4_..." 라 쓰고
>    ppc64le/s390x 절은 "icr.io_cpopen_cpd_..." — 실물은 cpopen 포함(9/2 실측 일치).
>    보정목록 D(파일명 표기 차이)의 근원이 IBM 문서 자체 오타였음을 확인
> ④ 검증 문구 확보: load 성공 메시지 = "Loaded image: icr.io/cpopen/cpd/olm-utils-v4:
>    ${VERSION}.amd64" (런북의 "olm-utils:latest" 메시지와 다름 — 5.3.x 기준이 정확)
> ⑤ 프리미엄(olm-utils-premium-v4) 분기는 모비스 표준 라이선스 → 해당 없음
> ```

## 본문 요지 + 명령 (모비스 해당 = 다른 워크스테이션 방식, x86-64)

인터넷 워크스테이션에서:
```bash
cpd-cli manage save-image \
--from=icr.io/cpopen/cpd/olm-utils-v4:${VERSION}.amd64
# → work/offline 에 tar.gz 저장 (실물명 icr.io_cpopen_cpd_olm-utils-v4_...)
```
tar 를 클러스터 쪽 워크스테이션의 work/offline 으로 전송 후:
```bash
cpd-cli manage load-image \
--source-image=icr.io/cpopen/cpd/olm-utils-v4:${VERSION}.amd64
# 성공: Loaded image: icr.io/cpopen/cpd/olm-utils-v4:${VERSION}.amd64
export OLM_UTILS_IMAGE=icr.io/cpopen/cpd/olm-utils-v4:${VERSION}.amd64
```
(같은 워크스테이션 반입 방식이면: 인터넷 연결 중 restart-container 로
pull 해두면 끝 — SUCCESS 3줄 확인)
