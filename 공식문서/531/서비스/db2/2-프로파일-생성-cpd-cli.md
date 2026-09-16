# 원문 — Creating a profile to use the cpd-cli management commands (5.3.x) `[2026-09-04 수집·전문]`

경로: 5.3.x → Administering → IBM Software Hub command-line
interface (cpd-cli) → **Creating a cpd-cli profile**
URL: https://www.ibm.com/docs/en/software-hub/5.3.x?topic=cli-creating-cpd-profile
문서 갱신일: 2026-03-26
연결: 체크리스트 No.73 (Db2 인스턴스 업그레이드용 프로파일) /
Db2 업그레이드 STEP 19 전제 / service-instance 계열 전부

## 목차

- [기존 수집 내용](#원문-전문)
- [사전확인 절차](#우리-사전확인-절차-현대모비스-step-19-전-은정님-정리)
- [GetToken 401 확인](#gettoken-401-확인)

> ★우리 판정:
> ```
> ① ★핵심 개념 — profile = OpenShift 로그인이 아니라
>    Software Hub(CPD) 인증. service-instance·user-mgmt·diag·
>    export-import 명령이 이걸 요구. oc login 과 별개.
> ② 저장 위치 = ★배스천 로컬 $HOME/.cpd-cli/config
>    (클러스터 리소스 아님 — 워크스테이션마다 만듦)
> ③ 구성 = 2단계:
>    (a) config users set  = username + apikey (로컬 사용자)
>    (b) config profiles set = url + 그 로컬 사용자 연결
> ④ API key 는 웹 UI(Profile and settings → Generate API key)
>    에서 발급. 만료 없음. ★재발급하면 users set 재실행 필요
> ⑤ URL 은 oc get route cpd 로 얻고 https:// 붙여 사용
> ⑥ 권한(can_provision / manage_service_instances)은 이 문서가
>    아니라 CPD 사용자 권한 — UI Access control 에서 확인
>    (은정님 정정: oc auth can-i 로 확인하는 게 아님)
> ⑦ Db2 인스턴스 업그레이드 전 실측: config users list /
>    config profiles list 로 기존 프로파일 유무 먼저 확인
> ```

---

## 원문 전문

Creating a profile to use the cpd-cli management commands
Last Updated: 2026-03-26

Before you can complete certain setup and management tasks
for IBM Software Hub, you must create a profile so that you
can run cpd-cli commands.

### Before you begin

Download and install Version 14.3.1 of the cpd-cli
command-line utility.

### About this task

프로파일이 필요한 명령(아래 중 하나라도 쓰면 프로파일 필수):
- cpd-cli diag (진단·헬스체크)
- cpd-cli user-mgmt (사용자 관리)
- cpd-cli service-instance (서비스 인스턴스 관리) ← ★Db2
- cpd-cli export-import (배포 간 데이터·메타데이터 이관)

"A profile enables the cpd-cli to verify that you are an
IBM Software Hub user and that you have the appropriate
permissions to complete a specific task."

- 인스턴스 여러 개면 인스턴스마다 프로파일 생성
- 인스턴스에 관리자 여럿이면 각자 프로파일 생성

### Procedure

1. 웹 클라이언트 Profile and settings → **Generate API key**
   로 API 키 발급. 이 키는 만료 없음. 설정은
   $HOME/.cpd-cli/config 에 저장됨.

2. 환경변수 설정:
```bash
export API_KEY=<api-key>
export CPD_USERNAME=<user-name>
export LOCAL_USER=<local-user>
export CPD_PROFILE_NAME=<cpd-profile-name>
export CPD_PROFILE_URL=<cpd-url>
```
   URL 얻기:
```bash
oc get route cpd --namespace=${PROJECT_CPD_INST_OPERANDS}
# 출력: cpd-namespace.apps.OCP-default-domain
# → 앞에 https:// 붙여서 사용
#   예: https://cpd-namespace.apps.OCP-default-domain
```

3. 로컬 사용자 구성 (username + API key):
```bash
cpd-cli config users set ${LOCAL_USER} \
--username ${CPD_USERNAME} \
--apikey ${API_KEY}
```
   ※API key 재발급하면 이 명령 재실행 필요.

4. 프로파일 생성 (URL + 로컬 사용자 연결):
```bash
cpd-cli config profiles set ${CPD_PROFILE_NAME} \
--user ${LOCAL_USER} \
--url ${CPD_PROFILE_URL}
```
   예시 config 구조:
```yaml
users:
- name: 682-d-engineer_1
  user:
    username: cpadmin
    apikey: {base64: c1BPZnhRZ1py...==}
- name: my_profile
  profile:
    type: private
    url: https://cpd-cpd-instance.apps.ivt564.cp.example.ibm.com
    user: 682-d-engineer_1
```

### Results

이 프로파일로 cpd-cli 실행:
```bash
cpd-cli service-instance list \
--profile=${CPD_PROFILE_NAME}
```

---

## 우리 사전확인 절차 (현대모비스 STEP 19 전) `[은정님 정리]`

```bash
# ① 기존 프로파일 유무 확인 (있으면 재사용)
cpd-cli config users list
cpd-cli config profiles list
#   NAME/USER/URL 나오면 export CPD_PROFILE_NAME=<그이름>

# ② 없으면 위 Procedure 대로 생성 (API key 발급 → users set → profiles set)

# ③ 권한 확인은 ★CPD UI (oc auth can-i 아님):
#    Administration > Access control > Users > 사용자 선택
#    > View assigned permissions
#    → "Create service instances"(can_provision) 또는
#      "Manage service instances"(manage_service_instances) 있어야 함

# ④ 동작 확인 — Db2 인스턴스 정상 조회되면 준비 완료:
cpd-cli service-instance list \
--service-type=db2oltp \
--profile=${CPD_PROFILE_NAME}
```

## GetToken 401 확인

추가일: 2026-09-16. 사용자 제공 로그에서 `service-instance list --service-type=db2oltp --profile=cpd-profile` 실행 시 `GetToken exception: Received status code: 401`을 확인했다. 아래 명령은 배스천에서 실행할 진단 안내이며, 이 문서 작성 중 클러스터에 접속하거나 인증 정보를 변경하지 않았다.

### 근거와 확인 범위

- 프로파일 구성은 위의 2026-09-04 저장본을 확인했다. [IBM 프로파일 생성 원문](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=cli-creating-cpd-profile)은 이번 조회에서 HTTP 403으로 열리지 않았다. 해당 부분은 **기존 수집본 기반 메모**다.
- [IBM 5.3.x config users list](https://www.ibm.com/docs/en/software-hub/5.3.x?topic=users-userslist)의 구문과 출력 옵션을 2026-09-16에 확인했다.
- [IBM cpd-cli 저장소의 프로파일 설정 예제](https://github.com/IBM/cpd-cli/blob/master/cpdtool/README.md)는 CPD 웹 콘솔의 API 키와 CPD route를 사용해 로컬 사용자와 프로파일을 연결한다.
- 후속 확인: 사용자가 같은 IBM URL의 **2026-09-11 갱신 본문**을 제공했다. Before you begin, About this task, Procedure, Results를 읽었다. 이 최신 내용은 **사용자 제공 원문 기반**이며, 5.3.x 문서의 CLI 전제는 `14.3.1.13`이다. 앞부분의 2026-09-04 수집 내용과 구분한다.

### 1. 저장된 설정과 접속 대상 확인

실행 위치: 오류가 발생한 배스천의 같은 Linux 계정. 현재 로그에서는 `root`다. 목적은 실제 CLI 버전, 프로파일 URL, 연결된 로컬 사용자와 CPD 사용자명을 확인하는 것이다. 로컬 설정 조회에는 OpenShift 관리자 권한이 필요하지 않다.

```bash
cpd-cli version
cpd-cli config profiles list
cpd-cli config users list
```

`cpd-profile`의 사용자 연결을 확인한다. `export CPD_PROFILE_NAME=cpd-profile`은 사용할 이름을 지정할 뿐, 프로파일을 생성하거나 로그인하지 않는다. 다른 Linux 계정에서 만든 설정은 현재 계정의 기본 설정 파일에 없을 수 있다. 공유할 출력에서는 API 키·토큰·비밀번호를 제외한다.

후속 사용자 출력에서 `cpd-profile → cpadmin-local → cpadmin` 연결과 CLI `14.4.0` / `SWH Release Version: 5.4.0`을 확인했다. 기본 프로파일 목록에는 URL이 표시되지 않았다. 이 출력은 저장된 키의 유효성을 증명하지 않으며, CLI의 릴리스 표시는 실제 클러스터의 CPD 설치 버전 확인을 대신하지 않는다. 실제 대상이 5.3.1이면 위 최신 5.3.x 문서의 CLI 전제와 맞춰야 하지만, 이번 `401`의 원인을 버전 차이라고 단정하지 않는다.

#### CPD URL과 네임스페이스를 모를 때

실행 위치: 기존 배스천 셸. 권한: `oc`로 클러스터에 로그인되어 있고 전체 네임스페이스의 Route를 조회할 수 있어야 한다. 이 명령은 리소스를 변경하지 않는다.

```bash
oc get route -A | awk 'NR==1 || $2 == "cpd"'
```

`NAME`이 `cpd`인 행의 `HOST/PORT` 앞에 `https://`를 붙이면 CPD 웹 URL이다. `NAMESPACE`는 해당 CPD 인스턴스의 네임스페이스다. 여러 행이 나오면 작업 대상 인스턴스를 선택한다. 헤더만 나오면 이름이 `cpd`인 Route가 조회되지 않은 것이므로 현재 클러스터와 Route 구성을 확인한다. `Forbidden`이면 조회 권한 문제, 로그인 요구 오류면 현재 `oc` 인증부터 확인한다.

이렇게 얻은 주소는 클러스터의 실제 Route이며, 기존 로컬 프로파일에 같은 URL이 저장되어 있는지는 별도 확인이 필요하다. 웹 콘솔에 `cpadmin`으로 접속해 Profile and settings에서 얻은 **그 사용자의 CPD API 키**를 사용한다. 사용자가 셸에 단독 입력한 `sha256~` 형식 문자열은 OpenShift 토큰 형식으로 보이며, 그 자체는 실행 명령이 아니다. 그것을 CPD `--apikey`에 넣었다면 올바른 CPD 사용자 API 키로 바꿔야 한다. 실제로 어떤 키가 저장됐는지는 아직 확인하지 않았다.

다음은 위 프로파일에 저장된 CPD 웹 URL로 통신을 확인하는 명령이다. URL에는 인증 정보를 넣지 않는다.

```bash
read -rp 'CPD web URL (https://host): ' CPD_URL
curl -sS --connect-timeout 5 --max-time 15 \
  -o /dev/null -w 'HTTP=%{http_code}\n' "$CPD_URL"
```

- HTTP 응답이 있으면 해당 주소에서 응답한 서버까지 통신한 것이다. CPD 사용자 인증 성공이나 모든 서비스의 정상 상태를 뜻하지 않는다.
- 이름 해석 실패·접속 시간 초과·인증서 오류면 API 키 변경 전에 DNS·네트워크·신뢰 인증서를 확인한다.
- 현재 `401` 로그만으로도 어떤 HTTP 서버가 응답했다는 사실은 알 수 있다. 다만 올바른 CPD 서버에 연결했는지는 프로파일 URL과 비교해야 한다.

통신이나 웹 로그인이 실패할 때 추가 확인한다. `CPD_HOST`에는 위 URL의 호스트명만, `CPD_NS`에는 실제 CPD operands 네임스페이스를 입력한다. `oc` 조회는 해당 리소스의 조회 권한과 현재 클러스터 로그인이 필요하다.

```bash
read -rp 'CPD route hostname: ' CPD_HOST
getent ahosts "$CPD_HOST"
ip route
read -rp 'CPD operands namespace: ' CPD_NS
oc get route cpd -n "$CPD_NS"
oc get pods -n "$CPD_NS"
```

### 2. 결과별 판단

| 확인 결과 | 다음 조치 |
| --- | --- |
| 프로파일 URL이 실제 CPD 웹 URL과 다름 | 올바른 인스턴스의 URL로 프로파일 수정 |
| 로컬 사용자에 연결된 CPD 사용자명이 키를 발급한 계정과 다름 | 같은 CPD 계정의 사용자명과 API 키로 수정 |
| CPD 키 대신 이미지 다운로드용 entitlement key나 OpenShift 토큰을 사용함 | 해당 CPD 웹 콘솔의 Profile and settings에서 발급한 사용자 API 키 사용 |
| 키를 재발급한 뒤 로컬 설정을 갱신하지 않음 | 현재 유효한 키로 로컬 사용자 설정 갱신 |
| 같은 사용자로 CPD 웹 로그인도 실패함 | 계정 상태와 인증 서비스를 우선 확인 |
| 토큰 발급은 성공하지만 이후 권한 오류나 빈 목록이 나옴 | CPD 서비스 인스턴스 권한과 사용자 연결 확인 |

`GetToken` 단계의 `401`은 토큰 획득 중 인증이 거부됐다는 뜻이다. 이 로그만으로 API 키 오류, 계정 문제, 잘못된 URL 중 하나를 확정할 수 없다. Db2 인스턴스 장애나 CLI 버전 불일치로도 단정하지 않는다.

### 3. 잘못된 인증 정보를 확인한 경우에만 수정

위 Procedure의 `config users set`에는 **프로파일이 참조하는 로컬 사용자 이름**, **실제 CPD 사용자명**, **그 CPD 사용자의 현재 API 키**를 함께 지정한다. URL이나 로컬 사용자 연결이 잘못됐다면 `config profiles set`도 수정한다. 키를 단순히 새 환경변수에 넣는 것만으로는 저장된 설정이 갱신되지 않는다.

기존에 유효한 키가 있다면 재사용한다. 키 재발급은 기존 키를 사용하는 다른 작업에도 영향을 줄 수 있으므로 첫 진단 단계에서 무조건 재발급하지 않는다.

수정 후 같은 배스천 계정에서 확인한다.

```bash
cpd-cli service-instance list \
  --service-type=db2oltp --profile=cpd-profile
```

성공 기준: `GetToken` 오류 없이 명령이 완료된다. 목록이 비어 있으면 사용자에게 보이는 Db2 인스턴스 유무와 권한을 별도로 확인한다.
