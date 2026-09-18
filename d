온싱, 이번에는 백업을 시작할 때 생기는 문제뿐 아니라, 백업 중간에 멈추는 문제·백업은 끝났는데 서비스가 안 살아나는 문제·복원할 때 뒤늦게 드러나는 문제까지 넓혀서 확인했어.
기준은 앞서 말한 CPD/IBM Software Hub 5.1.3 Patch 12 + 일반 NFS + OADP 오프라인 백업이야. 다만 아래에서 “IBM 5.1.x 공식 사례”라고 한 것은 해당 버전 문서에 실린 문제라는 뜻이지, 전부 Patch 12에서도 미해결이라는 뜻은 아니야. 다른 버전이나 특정 스토리지에서만 확인한 내용은 따로 구분했어.
가장 중요한 결론은 이거야.온싱, 이번에는 백업을 시작할 때 생기는 문제뿐 아니라, 백업 중간에 멈추는 문제·백업은 끝났는데 서비스가 안 살아나는 문제·복원할 때 뒤늦게 드러나는 문제까지 넓혀서 확인했어.
기준은 앞서 말한 CPD/IBM Software Hub 5.1.3 Patch 12 + 일반 NFS + OADP 오프라인 백업이야. 다만 아래에서 “IBM 5.1.x 공식 사례”라고 한 것은 해당 버전 문서에 실린 문제라는 뜻이지, 전부 Patch 12에서도 미해결이라는 뜻은 아니야. 다른 버전이나 특정 스토리지에서만 확인한 내용은 따로 구분했어.
가장 중요한 결론은 이거야.
CronJob 중지만으로 백업 준비가 끝나는 게 아니고, Backup=Completed만으로 복구 가능한 백업이라고 판정할 수도 없어.
실행 중인 Job·서비스 정지 상태·볼륨별 백업 결과·저장소 상태·posthook 결과를 각각 확인해야 해. �
Kubernetes +2
1. 먼저, 앞서 내가 말한 내용 중 바로잡을 부분
오프라인 백업 예시에는 --mode=offline이 필요해
IBM **5.1.x tenant-backup create 명령 참조의 --mode 기본값은 online**이야. 앞서 내가 오프라인 백업 설명에 제시한 명령에서 이 옵션을 생략한 건 잘못이었어.
또 같은 문서에서 **--scale-wait-timeout 기본값은 30m0s**야. 따라서 앞서 제시한 15m는 설치된 CLI에 따라 늘리는 게 아니라 줄이는 설정일 수 있어. 실제 설치된 버전의 --help로 확인해야 해. �
IBM
cpd-cli version
cpd-cli oadp version

cpd-cli oadp tenant-backup create --help
그리고 앞서 “hook에서 훨씬 자주 실패한다”, “이 문제가 가장 흔하다”라고 한 건 발생 빈도를 뒷받침할 근거 없이 한 표현이라 취소할게. 아래 순서는 발생 빈도가 아니라, 백업 안전성을 위해 먼저 확인할 순서야.
2. CronJob 관련해서 실제로 놓치기 쉬운 문제들
2-1. CronJob suspend=true여도 이미 생성된 Job은 계속 실행됨
이게 가장 중요한 구분이야.
CronJob을 suspend
    ├─ 앞으로 스케줄에 따라 생성할 Job → 중지
    └─ 이미 생성된 Job / Pod          → 계속 실행 가능
Kubernetes는 CronJob의 suspend가 이미 시작한 Job에 영향을 주지 않는다고 명시해. 따라서 CronJob을 멈췄어도 기존 Job이 DB를 수정하거나 PVC에 쓰고 있으면, 백업 시점의 쓰기 작업은 여전히 남아 있는 거야. �
kubernetes.io
점검 기준: CronJob SUSPEND=true만 보지 말고, 그 CronJob이 만든 미완료 Job과 해당 Pod까지 확인해야 해.
2-2. 기존 Job이 실패한 Pod를 다시 만들 수 있음
CronJob 스케줄러와 Job 컨트롤러는 별개야. Job은 성공 조건을 충족할 때까지 Pod를 재시도할 수 있고, Pod가 실패하거나 삭제되면 대체 Pod를 만들 수 있어. �
Kubernetes
그래서 이런 상황도 가능해.
CronJob suspend=true
        ↓
기존 Job은 아직 미완료
        ↓
그 Job의 Pod만 삭제
        ↓
Job 컨트롤러가 새 Pod 생성
“CronJob 멈췄는데 왜 Pod가 다시 생기지?”라면 먼저 Job의 owner 관계를 봐야 해. Pod만 반복해서 삭제하는 건 해결책이 아닐 수 있어.
참고로 Job 자체의 spec.suspend는 CronJob의 suspend와 다르게 활성 Pod를 종료시키는 동작이므로, 같은 의미로 생각하고 적용하면 안 돼. �
Kubernetes
2-3. concurrencyPolicy: Forbid는 전체 백업 중복 실행 방지 장치가 아님
Forbid는 동일한 CronJob이 만드는 Job 사이에만 적용돼. 다른 CronJob, 수동으로 실행한 cpd-cli, 별도 스케줄러가 시작한 작업까지 막아주지 않아. Replace는 이전 Job을 교체하므로, 백업 실행용 CronJob에 적용되어 있으면 진행 중 작업을 끊는 위험도 검토해야 해. �
kubernetes.io
즉, 아래가 각각 존재하면 충돌 여부를 따로 확인해야 해.
정기 백업 CronJob
수동 cpd-cli 백업
다른 운영 서버의 백업 스크립트
Velero Schedule
이 네 개를 하나의 CronJob에 설정한 Forbid로 통제할 수는 없어.
2-4. suspend를 해제하자마자 누락된 작업이 실행될 수 있음
특히 startingDeadlineSeconds가 설정되지 않은 CronJob은 재개 시 누락된 실행이 즉시 예약될 수 있어. 따라서 서비스가 아직 복구 중인데 CronJob부터 재개하면 maintenance·cleanup·배치 작업이 바로 시작하는 상황을 고려해야 해. �
kubernetes.io
내가 권하는 운영 순서는 다음이야.
백업 데이터 처리 종료 확인 → CPD posthook 및 서비스 상태 확인 → 원래 활성 상태였던 CronJob만 재개.
중지 이전부터 suspend=true였던 CronJob까지 일괄적으로 false로 바꾸면 안 돼.
2-5. 스케줄 시간과 실행 제한 시간을 혼동하는 문제
항목
의미와 주의점
.spec.timeZone
지정하지 않으면 컨트롤러의 시간대를 기준으로 스케줄을 해석해. 운영자가 생각한 한국 시간과 같은지 확인해야 해.
startingDeadlineSeconds
늦어진 스케줄을 언제까지 시작할 수 있는지에 대한 제한이야. 실행 중 Job의 최대 수행 시간이 아니야.
Job의 activeDeadlineSeconds
Job 실행 시간 제한 쪽 설정이야. 장시간 백업을 감싼 Job에 짧게 설정되어 있으면 작업 종료 원인이 될 수 있어.
앞의 두 항목은 CronJob, 마지막은 Job 설정이므로 구분해서 봐야 해. �
Kubernetes +1
2-6. cleanup-completed-resources는 CronJob 중지가 아님
IBM의 --cleanup-completed-resources는 완료된 Job·Pod를 정리하는 옵션이야. CronJob의 다음 실행을 막거나, 실행 중인 Job을 안전하게 종료하는 기능으로 보면 안 돼. �
IBM
따라서 아래는 서로 다른 작업이야.
완료된 Job/Pod 정리
예약된 실행 차단
기존 실행 작업 종료 확인
2-7. CronJob 목록에는 안 보이는 예약·유지보수 작업이 있음
Velero Schedule은 Kubernetes CronJob이 아닌 별도 CR이야. oc get cronjob만 확인하면 놓쳐. 또한 Velero 문서상 스케줄에서 수동 백업을 시작해도 다음 정기 실행 시각은 바뀌지 않으므로, 수동 작업과 정기 작업의 시간 중첩을 고려해야 해. �
Velero
그리고 Velero 1.14부터 repository maintenance를 별도 Kubernetes Job으로 실행하는 구조가 도입됐어. 이전 버전은 Velero 서버 Pod 내부에서 maintenance를 실행했기 때문에, 설치된 Velero 버전에 따라 점검 대상이 달라져. 이 Job을 CPD의 불필요한 배치라고 생각해서 일괄 삭제하면 안 돼. �
Velero
oc get schedules.velero.io -n <oadp-namespace>
oc get jobs.batch -n <oadp-namespace>
2-8. zen-rsi-evictor-cron-job은 존재 여부와 적용 버전을 구분해야 함
IBM 5.3.x Known Issues에는 zen-rsi-evictor-cron-job이 30분마다 RSI 패치가 필요한 Pod를 확인하고 미패치 Pod를 퇴거시키는 동작이 설명돼 있어. 한편 이 CronJob의 활성화 명령은 5.1.x 업그레이드 문서에서도 검색돼. �
IBM +1
따라서 정확한 정리는 이거야.
“5.1.3이니까 이 CronJob은 없다”도 단정하면 안 되고, “5.3 문서에 있으니까 5.1.3 Patch 12도 동일한 백업 결함에 걸린다”도 단정하면 안 돼.
실제 존재 여부, 현재 suspend 상태, 최근 실행 시각, 생성된 Job, 해당 패치 수준의 IBM 지침을 함께 확인해야 해.
2-9. 복원 후 CronJob이 너무 일찍 동작하는 위험
이건 특정 CPD 버그라고 확인된 것이 아니라, 활성 CronJob이 스케줄에 따라 Job을 생성한다는 Kubernetes 동작에서 도출되는 운영상 위험이야.
복원된 CronJob이 활성 상태이고 서비스 복구가 아직 진행 중이라면, 데이터 정리나 배치 작업이 준비되지 않은 서비스에 접근할 수 있어. 반대로 백업 당시의 중지 상태가 남아 있으면, 복원 후 정기 작업이 계속 멈춰 있을 수도 있어. 복원 완료 확인에 CronJob 상태 비교를 넣는 이유야. �
Kubernetes
CronJob 관리에서 내가 권하는 기준
서비스의 공식 백업 hook이 관리하는 대상인지 먼저 확인하고, 추가 통제가 필요한 CronJob만 대상으로 삼는 게 좋아. 이름에 cleanup, backup, maintenance가 들어간다는 이유만으로 중지 대상으로 확정하지는 말자.
운영 절차에는 원래 suspend 상태 보관 → 필요한 대상만 중지 → 미완료 Job 확인 → 백업·서비스 복구 확인 → 원래 상태로 복구를 넣는 것을 권해. 이는 위 동작을 고려한 운영 권고이고, IBM의 일괄 CronJob 중지 명령이라는 뜻은 아니야.
3. CronJob 외에, IBM 5.1.x에 문서화된 백업 실패 사례
아래는 백업 전에 확인할 항목과 오류 발생 시 확인 방향을 묶은 거야.
3-1. 사전 검사·서비스 정지·마운트 단계
문제
증상·조건
확인하거나 조치할 방향
백업용 ConfigMap 누락
global registry check failed, 특정 *-aux-*-cm이 not found. 업그레이드 이후나 수동 삭제 뒤 발생할 수 있음.
IBM은 해당 서비스 CR의 spec.last_br_recon 변경으로 reconciliation을 유도하는 방법을 안내해. 검사를 skip해서 숨길 문제가 아니야. �
IBM
서비스/리소스 정지 대기 timeout
timed out waiting for the condition. 종료 대기 중인 Pod 등의 상태를 확인해야 함.
어떤 리소스를 기다렸는지 로그에서 먼저 식별하고, 실제 종료가 느린 경우에 해당 대기 시간을 검토. 모든 timeout을 DPA 하나로 해결하지 않기. �
IBM
cpdbr-vol-mnt Pod 메모리 부족
오프라인 백업이 진행 중에 멈추거나 exit 137로 실패하는 IBM 사례.
IBM은 마운트 Pod 메모리 request/limit 조정을 안내해. Velero 메모리를 늘리는 것과 별개야. 실제 종료 이유가 OOMKilled인지 확인해야 해. �
IBM
이전 backup/checkpoint 작업이 진행 중이라고 판단됨
새 작업을 시작할 때 already in progress 계열 오류.
실제 진행 중인 작업과 비정상 종료 후 남은 상태를 먼저 구분. 프로세스 확인 없이 checkpoint reset부터 하지 않기. 이 유형은 IBM 5.1.x 문제해결 목록에 별도 항목으로 존재해. �
ibm.com
마운트 Pod가 시작되지 못함
cpdbr-vol-mnt의 생성·마운트가 지연되고 timeout.
Pod Events로 이미지 pull, 스케줄링, 볼륨 mount 문제를 분리. IBM 5.2.x의 관련 문서는 높은 부하에서 CRI-O의 volume 설정·컨테이너 생성 지연을 설명해. 이 상세 조건은 5.2.x에서 확인한 것이야. �
IBM
특히 ConfigMap 누락은 “백업 기능 자체가 덜 준비된 상태”일 수 있어
예를 들어 IBM 문서에는 다음처럼 백업용 ConfigMap을 찾지 못하는 사례가 나와.
cpd-ikc-ccs-aux-ckpt-cm not found
이때 단순히 ConfigMap 이름 하나를 만들어 넣거나 --skip-hooks로 통과시키는 방식보다, 해당 서비스가 제공해야 하는 백업 구성이 제대로 생성되도록 복구하는 것이 우선이야. �
IBM
3-2. S3·BSL·인증 관련
문제
증상·조건
확인하거나 조치할 방향
BackupStorageLocation이 Unavailable
백업 대상 저장소 검증 실패.
BSL 상태·메시지, 실제 bucket, endpoint, credential 설정 확인. Available은 기본 점검 항목이지 전체 백업 성공 보장은 아님. �
ibm.com
Bucket이 존재하지 않음
bucket does not exist.
DPA/BSL에 적힌 bucket과 실제 저장소의 bucket이 일치하는지 확인. IBM 5.1.x에 별도 문제해결 항목이 있어. �
IBM
S3 인증서 오류
S3 연결 과정의 certificate 오류.
저장소 인증서·신뢰 설정 확인 대상. 운영 환경에서 검증 해제를 기본 해결책으로 삼지 않기. IBM 목록에 별도 사례가 존재하고, CLI 문서도 insecure 옵션의 운영 사용을 권장하지 않아. �
IBM +1
MinIO request signature 오류
The request signature we calculated does not match....
IBM의 특정 MinIO 사례는 credential 문제를 다루며 영숫자 credential 사용을 안내해. S3 전체에서 특수문자가 금지된다는 뜻은 아니야. �
IBM
MinIO에서 NoSuchKey
백업 로그나 velero-backup.json 업로드 과정에서 specified key 오류.
bucket·credential 파일·DPA 설정 확인. 앞쪽 로그에 Backup completed가 있더라도 뒤의 메타데이터 업로드 오류를 봐야 해. �
IBM
로그 조회만 SignatureDoesNotMatch
백업 데이터 처리와 별개로 로그 다운로드가 실패할 수 있음.
Velero는 임시 서명 URL을 사용하므로 S3 호환 구현의 서명 처리도 확인 대상이야. “로그 조회 실패=볼륨 백업 실패”로 바로 등치시키면 안 돼. �
Velero
실무적으로는 “S3 접속된다”를 한 번 확인하는 것보다, 해당 백업이 필요한 데이터와 메타데이터를 실제로 저장하고 다시 읽을 수 있는지까지 확인하는 게 중요해. IBM도 별도 S3 클라이언트를 이용한 읽기·쓰기 확인을 기본 진단에 포함해. �
ibm.com
3-3. Restic repository·데이터 전송·메모리 관련
문제
증상·조건
확인하거나 조치할 방향
Repository lock
repository is already locked. IBM 5.1.x 공식 항목.
다른 백업·복원·maintenance 작업이 실제로 사용 중인지 먼저 확인. 중단된 작업의 잔여 lock인지 구분한 뒤 지원 절차로 처리해야 해. �
IBM +1
Repository config object가 사라짐
unable to open config file, specified key does not exist.
IBM은 object storage의 Restic 디렉터리를 지웠는데 repository CR은 남은 경우를 설명해. 저장소 파일과 Kubernetes 상태가 불일치한 문제야. �
IBM
Repository pruning 중 실패
error pruning repository, Velero OOMKilled.
IBM은 Velero/node-agent 메모리 설정을 검토하도록 안내해. 예시 수치를 그대로 넣기보다 실제 사용량·노드 여유·quota와 맞춰야 해. �
IBM
PodVolumeBackup/Restore timeout
볼륨 데이터 처리 완료 대기 timeout.
IBM이 제시하는 관련 설정은 DPA의 spec.configuration.nodeAgent.timeout. scale 대기와 별개야. �
IBM
백업 중 Velero 또는 대상 Pod 재시작
InProgress에서 멈춰 보임.
Velero 1.14 문서는 중단된 백업을 자동으로 이어서 처리하지 못하는 경우를 설명해. 재시작만으로 정상 완료될 거라고 기대하면 안 돼. �
Velero
Repository maintenance가 리소스를 소모
backup과 maintenance가 겹치는 시간대에 CPU·메모리 부담.
Velero 버전에 따라 서버 Pod 내부 또는 별도 Job을 조사. node-agent만 보지 말고 maintenance 실행 주체도 확인. �
Velero
Repository 비밀번호를 뒤늦게 변경
기존 백업 repository에 접근하지 못함.
Velero는 첫 백업으로 repository를 만든 뒤 velero-repo-credentials의 비밀번호를 바꾸면 이전 백업에 연결하지 못할 수 있다고 경고해. S3 접근 키와 repository 비밀번호를 혼동하지 말아야 해. �
Velero
저장소가 꼬였을 때 특히 하면 안 되는 것
“다시 백업하면 되겠지” 하고 bucket 안의 Restic/Kopia 데이터를 수동으로 정리하는 건 위험해.
IBM은 repository 파일 수동 삭제 후 CR과의 불일치 사례를 문서화했고, Restic도 repository 파일 손실·삭제가 손상 원인이 될 수 있다고 설명해. 복구 작업 전에는 가능한 한 원본 repository를 보존하고, 추가 변경 작업을 통제하는 절차가 필요해. �
IBM +1
그래서 아래는 원인 확인 전에 일괄 실행할 명령이 아니야.
bucket 내부 파일 삭제
repository CR 전체 삭제
강제 unlock
checkpoint reset
finalizer 강제 제거
오류 메시지가 같아도 “현재 작업 중인 잠금”과 “죽은 작업의 잠금”, “인증 실패”와 “실제 object 손실”은 처리가 달라.
4. NFS 환경에서 별도로 봐야 하는 문제
4-1. EFS 전용 이슈를 일반 NFS 문제로 확대하면 안 됨
IBM Known Issues에는 동적으로 프로비저닝한 Amazon EFS 볼륨을 포함한 Restic 백업이 복원에서 실패하는 항목이 있어. 하지만 일반 NFS라는 사실만으로 동일한 EFS 결함에 해당한다고 볼 수는 없어. �
IBM
따라서 네 환경에서는 먼저 실제 provisioner와 백업 방식을 확인하고 판단해야 해. “NFS니까 무조건 Kopia로 바꾸자”라는 결론은 아직 근거가 부족해.
4-2. 읽기는 되는데 복원 시 파일 생성·소유권 처리가 실패할 수 있음
일반 NFS에서도 권한은 별도 점검 대상이야. NFS 서버는 root_squash 설정에 따라 클라이언트의 root 접근을 nobody로 매핑할 수 있어. 따라서 컨테이너 안에서 root라고 해서 NFS 서버에서도 같은 권한을 갖는 건 아니야. �
레드햇 문서
이 동작을 고려하면, 다음 오류에서는 백업 프로그램뿐 아니라 NFS export와 UID/GID·디렉터리 권한을 함께 조사해야 해.
Permission denied
Operation not permitted
chown / lchown 관련 실패
파일 또는 디렉터리 생성 실패
백업 읽기 성공과 복원 쓰기·권한 복구 성공을 별도 테스트하는 것을 권해. 그렇다고 원인 확인 없이 모든 export에 no_root_squash를 적용하라는 뜻은 아니야.
4-3. PVC가 존재한다고 실제 파일이 백업되는 건 아님
Velero FSB는 Pod에 마운트된 파일시스템을 통해 데이터를 읽어. Pod에 마운트되지 않은 PVC는 별도 준비 없이 동일하게 백업할 수 없고, CPD의 마운트 Pod가 정상적으로 준비되었는지도 중요해. �
Velero
따라서 확인해야 할 것은 단순한 PVC 개수가 아니라 다음 관계야.
백업 대상 PVC
   → 어느 Pod/볼륨으로 마운트되었는가
   → 해당 데이터 백업 작업이 생성되었는가
   → 그 작업이 완료되었는가
4-4. NFS 용량만 보고 백업 시간을 예상하면 빗나갈 수 있음
Velero 문서는 큰 파일은 변경량이 작더라도 중복 제거를 위한 스캔 시간이 오래 걸릴 수 있다고 설명해. 특히 DB 파일은 “이번에 바뀐 데이터가 얼마 안 되니까 금방 끝날 것”이라고 단정하기 어려워. �
Velero
운영 측면에서는 총 용량 외에 파일 구성, NFS 응답, 같은 시간대의 다른 I/O, 실제 전송 진행률을 함께 보는 게 좋아.
4-5. CPD 외부에서도 같은 파일을 수정한다면 정합성 범위를 다시 봐야 함
FSB는 한순간을 고정한 스냅샷이 아니라 실행 중인 파일시스템을 읽는 방식이야. 따라서 CPD 서비스를 정지했더라도, 별도 시스템이 같은 경로를 계속 수정한다면 일관된 백업 시점이라는 전제가 깨질 수 있어. 이는 FSB 동작에서 도출되는 운영상 위험이야. �
Velero
CPD Pod가 내려갔는지뿐 아니라, 백업 대상 데이터에 쓰는 다른 주체가 있는지도 확인할 것을 권해.
5. “백업은 성공했는데 복원이 실패하는” 문제들
이 부분은 백업 전에 알아둬야 해. 장애가 난 뒤에 처음 확인하면 복구 시간이 길어질 수 있으니까.
5-1. IBM 5.1.x에 문서화된 복원 사례
문제
IBM 문서의 원인·증상
중요한 대응 구분
오프라인 restore posthook이 일부만 성공
Posthook Status: partially_succeeded, post-processing 오류.
해당 사례에서 IBM은 restore posthook 재실행을 안내해. 데이터 복원 전체를 무조건 처음부터 다시 하는 문제와 구분해야 해. �
IBM
lite-cr가 복원되지 않음
zenservices... "lite-cr" not found, cpd-lite-aux-br-cm posthook 오류.
누락된 zenService 복원 단계가 문제. timeout을 늘려도 없는 CR이 생기지는 않아. �
IBM
Create OperandRequest Timeout
복원이 오래 진행된 뒤 실패.
IBM은 ODLM이 instance namespace의 Role/RoleBinding을 설치하지 못한 경우를 주요 원인으로 설명해. operator·instance namespace의 OperandRequest 상태를 함께 확인. �
IBM
Db2U StatefulSet이 Ready가 되지 않음
c-db2oltp-wkc-db2u가 0/1, Pod 생성 Forbidden, SCC 검증 실패.
오래된 SCC가 원인인 공식 사례가 있어. 백업 데이터나 NFS 속도 문제가 아니라 보안 정책 잔재일 수 있음. �
IBM
OpenSearch Pod가 Ready가 되지 않음
인덱스가 red, Pod 반복 시작, shard 문제.
IBM은 큰 인덱스 복구의 대기 시간 문제와 실제 shard 손상을 구분해. 손상이면 timeout 증가만으로 해결되지 않고 snapshot 복구·재인덱싱 등 별도 판단이 필요해. �
IBM
주의: 위 문서 중에는 namespace나 SCC 정리 후 재복원을 안내하는 경우가 있어. 그 명령은 복원 대상과 정리 범위를 확정한 뒤 적용해야 해. 운영 중인 원본 클러스터에서 그대로 복사해 실행할 내용은 아니야.
5-2. 기존 리소스가 남아 있어서 “복원한 줄 알았는데 안 바뀌는” 문제
Velero의 기본 복원 동작은 기존 리소스를 무조건 덮어쓰지 않아. 대상 리소스가 이미 존재하면 건너뛰는 동작이 있고, existing-resource-policy=update도 PVC 내부 데이터를 덮어쓰는 기능은 아니야. �
Velero
그래서 다음 생각은 위험해.
“기존 CPD와 PVC가 그대로 있어도 restore를 한 번 실행하면 백업 시점으로 싹 돌아가겠지.”
CPD의 동일 클러스터 복원 절차에서 무엇을 남기고 무엇을 정리하는지를 따라야 해.
5-3. API·CRD·admission webhook 때문에 리소스가 복원되지 않는 문제
Velero는 복원할 리소스의 API를 대상 클러스터에서 발견하지 못하면 복원 대상에서 제외할 수 있어. 또 admission webhook이 리소스 생성을 차단하거나 변경하면 예상하지 못한 복원 실패가 발생할 수 있어. �
Velero +1
이 때문에 다른 클러스터로 복원할 때는 OCP·Operator·CRD·보안 설정을 데이터 백업과 별개로 맞춰야 하는 부분이 있어. “S3에 데이터 있으니 아무 클러스터에나 복원된다”는 방식으로 접근하면 안 돼.
5-4. Pending이라고 전부 장애는 아님
StorageClass가 WaitForFirstConsumer라면 소비할 Pod가 준비될 때까지 PVC 바인딩·프로비저닝을 미룰 수 있어. 반대로 스케줄링 조건이 맞지 않으면 그 단계에서 계속 막힐 수도 있어. PVC 상태와 그것을 사용할 Pod의 Events를 같이 봐야 해. �
Kubernetes
따라서 앞서 내가 제시했던 grep Pending 같은 명령은 후보를 찾는 용도이지, 나온 것을 전부 장애로 판정하는 명령은 아니야.
6. 백업 “누락”과 보관·삭제 문제도 별도로 확인해야 해
6-1. 필터·라벨 때문에 필요한 리소스가 빠지는 문제
Velero는 namespace, resource type, label selector, resource policy 등으로 대상을 제한할 수 있어. 특히 다음 라벨이 있으면 selector에 맞더라도 제외될 수 있어.
velero.io/exclude-from-backup: "true"
따라서 백업 실패 오류가 없더라도 원래 의도한 리소스가 필터 때문에 빠진 것은 아닌지 확인해야 해. �
Velero
Completed는 “선택된 작업을 완료했다”는 뜻으로 읽어야지, “내가 필요로 하는 모든 것을 선택했다”는 증거로 읽으면 안 돼.
6-2. 백업 CR 삭제와 저장소 데이터 삭제를 혼동하는 문제
Velero 문서는 Kubernetes에서 Backup CR만 삭제하는 것과 Velero의 백업 삭제 작업을 구분해. 삭제 방식에 따라 object storage에 관련 데이터가 남을 수 있어. CPD에서는 해당 버전의 tenant/backup 삭제 절차를 기준으로 정리해야 해. �
Velero
IBM 5.1.x에는 백업이 계속 Deleting 상태로 남는 문제도 별도 문제해결 항목으로 실려 있어. 그래서 Deleting을 보고 곧바로 finalizer를 제거하거나 bucket을 지우는 방식은 피해야 해. �
ibm.com
6-3. GitOps나 owner reference로 Backup CR이 반복 삭제되는 문제
Velero 문서에는 Schedule과 Backup 사이에 owner reference를 설정한 경우, Schedule 삭제에 따라 Backup CR이 garbage collection되고, 저장소 동기화가 이를 다시 만들어 삭제·재생성이 충돌하는 상황이 설명돼 있어. GitOps가 백업 리소스를 관리한다면 이 관계도 확인 대상이야. �
Velero
6-4. 보관 기간과 object storage 정책이 서로 다른 문제
내가 권하는 점검은 CPD/Velero의 보관 기간과 object storage 쪽 삭제·보존 정책을 함께 대조하는 것이야. 특히 repository 내부 object가 별도 정책이나 수동 작업으로 없어지면, Kubernetes에 Backup 항목이 남아 있다고 해서 데이터를 복구할 수 있는 것은 아니야. 파일 손실이 repository 손상 원인이라는 점은 Restic 문서에도 명시돼 있어. �
Restic Documentation
7. 조건이 달라서 별도로 분류해야 하는 추가 공식 항목
아래는 IBM 5.1.x OADP 문제해결 목록에서 존재를 확인한 항목들이야. 다만 이번에 모든 개별 본문과 Patch 12 수정 여부까지 확인한 것은 아니므로, 해결 방법을 임의로 붙이지 않았어. 온라인 전용·스토리지 전용 이슈를 네 오프라인 NFS 환경의 확정 결함으로 섞으면 안 돼. �
ibm.com
적용 조건
추가 확인할 공식 문제
온라인 백업/복원
Knowledge Catalog glossary가 올바르게 복원되지 않는 문제, Data Privacy masking flow job이 복원 후 시작되지 않는 문제
온라인 백업/복원
PVC가 Bound가 되지 않는 문제, 일부 작업이 timeout으로 PartiallyFailed가 되는 문제
온라인 백업/복원
이전 작업의 in-progress 상태 때문에 다음 작업이 실행되지 않는 문제
Watson Studio의 기존 Git 프로젝트
온라인 복원 후 동기화되지 않는 문제
IBM Storage Scale
실패한 온라인 복원 후 PVC 파일이 남는 문제
AWS 관련 환경
cpdbr-vol-mnt Pod가 Pending으로 남는 문제
Snapshot 방식
최대 snapshot 개수 관련 오류
복원 대상·저장소
Backup not found, 복원 리소스 누락
이 항목들은 해당 서비스나 방식이 실제로 포함될 때 추가 조사할 목록이야. 예를 들어 일반 NFS의 파일 백업을 쓰는데 AWS snapshot 한도부터 조정하는 건 방향이 잘못된 거지.
8. timeout은 이렇게 구분해야 해
앞서 물어본 resourceTimeout도 이 구분 안에서 판단해야 해.
설정
관련 대기
판단 기준
cpd-cli ... --scale-wait-timeout
서비스 scale 관련 대기
IBM 5.1.x 명령 참조는 기본 30m0s. 설치된 CLI 확인 필요. �
IBM
DPA spec.configuration.nodeAgent.timeout
Pod volume 백업·복원 처리 대기
IBM의 Pod volume timeout 문제해결에서 조정하는 항목. 문서 예시값을 전체 환경의 기본값으로 보면 안 됨. �
IBM
DPA spec.configuration.velero.resourceTimeout
별도의 전용 timeout으로 다루지 않는 리소스 처리 대기
Red Hat 문서는 기본 10분으로 설명하지만, 설치된 OADP 버전과 스키마를 확인해야 함. 전체 CPD 백업 시간 제한이 아님. �
레드햇 문서
서비스 hook·Job 자체의 제한
특정 hook 또는 Job 수행
해당 hook 로그와 Job 설정을 조사해야 함. 다른 계층의 timeout을 늘려도 직접 해결되지 않을 수 있음. �
IBM +1
이런 문제는 timeout을 늘리는 것으로 해결되지 않아.
존재하지 않는 bucket
잘못된 credential
누락된 lite-cr / 백업 ConfigMap
SCC 때문에 Forbidden인 Pod
계속 재생성되는 쓰기 작업
삭제된 repository object
반대로 실제 데이터 전송이나 정상적인 복구가 진행 중이고, 측정된 소요 시간이 제한을 넘는 경우라면 해당 계층의 timeout 증가를 검토할 수 있어.
9. 네 환경에서 실행해 볼 읽기 전용 점검 명령
아래는 조회용이야. NS, OPNS, OADP는 해당 사이트의 실제 값으로 넣어. 이전 출력의 zen, oadp-operator를 다른 사이트에도 자동으로 적용하면 안 돼.
NS="<CPD instance namespace>"
OPNS="<CPD operator namespace>"
OADP="<OADP namespace>"
9-1. 버전·DPA·저장소·현재 작업
oc version
cpd-cli version
cpd-cli oadp version

oc get csv -n "$OADP"
oc get sc

oc get dpa -n "$OADP" -o yaml
oc get backupstoragelocations.velero.io -n "$OADP"

oc get backups.velero.io -n "$OADP"
oc get restores.velero.io -n "$OADP"

oc get schedules.velero.io -n "$OADP"
oc get backuprepositories.velero.io -n "$OADP"
oc get jobs.batch -n "$OADP"
버전·StorageClass·BSL 확인은 IBM 기본 진단 항목이고, repository·volume 작업은 Velero 진단 대상이야. 리소스 종류가 없다는 오류는 버전·설치 구성 차이일 수 있으므로, 빈 목록과 구분해야 해. �
IBM +1
9-2. CronJob 상태를 정확히 조회
앞서 내가 .status.active를 숫자처럼 설명한 부분도 수정할게. CronJob의 status.active는 참조 목록이므로 개수를 세어야 해. 아래는 jq가 필요해.
oc get cronjobs.batch -n "$NS" -o json |
jq -r '
  ["NAME","SUSPEND","ACTIVE_COUNT","SCHEDULE","TIMEZONE","POLICY","LAST"],
  (.items[] | [
    .metadata.name,
    (.spec.suspend // false),
    ((.status.active // []) | length),
    .spec.schedule,
    (.spec.timeZone // "<controller timezone>"),
    (.spec.concurrencyPolicy // "Allow"),
    (.status.lastScheduleTime // "-")
  ])
  | @tsv
'
각 항목은 CronJob API의 spec/status를 읽는 거야. 필요한 경우 operator namespace에도 같은 조회를 반복하면 돼. �
Kubernetes
9-3. ACTIVE=0이어도 미완료인 Job까지 확인
아래는 Complete 또는 Failed의 최종 조건이 아직 붙지 않은 Job을 찾는 조회야. 재시도 대기 중이라 현재 활성 Pod가 없는 경우를 놓치지 않기 위한 거야. Job은 Pod 재시도와 최종 완료 상태를 별도로 관리해. �
Kubernetes
oc get jobs.batch -n "$NS" -o json |
jq -r '
  ["NAME","OWNER","ACTIVE","SUCCEEDED","FAILED","START"],
  (.items[]
   | select(
       ([.status.conditions[]?
         | select(
             (.type == "Complete" or .type == "Failed")
             and .status == "True"
           )
        ] | length) == 0
     )
   | [
       .metadata.name,
       ((.metadata.ownerReferences // [])
         | map(.kind + "/" + .name) | join(",")),
       (.status.active // 0),
       (.status.succeeded // 0),
       (.status.failed // 0),
       (.status.startTime // "-")
     ])
  | @tsv
'
여기 나온 Job은 삭제 목록이 아니라 조사 목록이야. owner와 수행 내용을 확인해야 해.
9-4. 볼륨별 결과와 Pod 상태
oc get podvolumebackups.velero.io -n "$OADP" \
  -o custom-columns='NAME:.metadata.name,NS:.spec.pod.namespace,POD:.spec.pod.name,VOLUME:.spec.volume,PHASE:.status.phase,MESSAGE:.status.message'

oc get podvolumerestores.velero.io -n "$OADP"

oc get pods -n "$NS" -o wide
oc get pvc -n "$NS"

oc get pods -n "$OADP" -o wide
oc get daemonsets -n "$OADP"

oc get events -n "$NS" --sort-by=.metadata.creationTimestamp
oc get events -n "$OADP" --sort-by=.metadata.creationTimestamp
FSB 방식에서는 대상 Backup에 연결된 PodVolumeBackup/Restore 결과를 확인해야 해. CSI snapshot·data mover 등 다른 방식을 사용하면 필요한 확인 리소스가 달라지므로, PVB가 없다는 사실만으로 실패라고 판단하지는 마. �
Velero
문제가 생긴 Pod는 다음으로 좁혀 보면 돼.
oc describe pod <problem-pod> -n <namespace>
oc logs <problem-pod> -n <namespace> -c <container>
oc logs <problem-pod> -n <namespace> -c <container> --previous
현재 로그만 보면 재시작 전에 발생한 OOM·실패 원인을 놓칠 수 있으니, 종료 상태와 이전 컨테이너 로그도 함께 보는 것을 권해.
10. 이번 백업에서 적용할 완료 판정 기준
내가 운영 점검표를 만든다면, 완료 조건을 다음 세 묶음으로 잡겠어.
백업 준비: 버전과 실행 모드가 맞고, 필요한 백업 ConfigMap과 사전 검사가 통과했으며, 의도하지 않은 쓰기 Job이 남아 있지 않을 것.
백업 결과: tenant 작업 결과뿐 아니라 실제 생성된 Backup과 해당 볼륨 데이터 작업이 정상 종료했고, 필요한 리소스가 필터로 빠지지 않았으며, 저장소의 관련 데이터·메타데이터를 읽을 수 있을 것.
운영 복귀·복구 가능성: posthook이 성공하고 서비스가 정상화됐으며, CronJob이 원래 상태로 돌아왔고, 별도 복원 검증으로 실제 복구 가능성을 확인할 것. 이 기준은 위의 IBM hook 실패 사례와 Velero의 볼륨별 확인·필터링 동작을 고려한 운영 권고야. �
IBM +3
네 환경에서 우선적으로 보겠다는 것은 resourceTimeout 일괄 증가가 아니라, CronJob + 미완료 Job, 백업용 ConfigMap, cpdbr-vol-mnt, BSL/repository, 볼륨별 결과, posthook 상태야.
마지막으로 조사 범위는 분명히 할게. IBM 5.1.x OADP 문제해결 목록과 여러 개별 본문, Kubernetes·Velero·Red Hat의 관련 동작을 확인했지만, IBM Known Issues 일부 페이지는 접근 오류로 전체 본문을 읽지 못했고 Patch 12별 수정 여부도 전부 교차 검증하지 못했어. 그래서 위 내용을 “Patch 12에서 현재 발생하는 모든 확정 버그”라고 부르지는 않을게. 대신 공식 사례·일반 동작·조건부 위험을 구분한 사전 점검 및 장애 분석 목록으로 쓰는 게 정확해.
CronJob 중지만으로 백업 준비가 끝나는 게 아니고, Backup=Completed만으로 복구 가능한 백업이라고 판정할 수도 없어.
실행 중인 Job·서비스 정지 상태·볼륨별 백업 결과·저장소 상태·posthook 결과를 각각 확인해야 해. �
Kubernetes +2
1. 먼저, 앞서 내가 말한 내용 중 바로잡을 부분
오프라인 백업 예시에는 --mode=offline이 필요해
IBM **5.1.x tenant-backup create 명령 참조의 --mode 기본값은 online**이야. 앞서 내가 오프라인 백업 설명에 제시한 명령에서 이 옵션을 생략한 건 잘못이었어.
또 같은 문서에서 **--scale-wait-timeout 기본값은 30m0s**야. 따라서 앞서 제시한 15m는 설치된 CLI에 따라 늘리는 게 아니라 줄이는 설정일 수 있어. 실제 설치된 버전의 --help로 확인해야 해. �
IBM
cpd-cli version
cpd-cli oadp version

cpd-cli oadp tenant-backup create --help
그리고 앞서 “hook에서 훨씬 자주 실패한다”, “이 문제가 가장 흔하다”라고 한 건 발생 빈도를 뒷받침할 근거 없이 한 표현이라 취소할게. 아래 순서는 발생 빈도가 아니라, 백업 안전성을 위해 먼저 확인할 순서야.
2. CronJob 관련해서 실제로 놓치기 쉬운 문제들
2-1. CronJob suspend=true여도 이미 생성된 Job은 계속 실행됨
이게 가장 중요한 구분이야.
CronJob을 suspend
    ├─ 앞으로 스케줄에 따라 생성할 Job → 중지
    └─ 이미 생성된 Job / Pod          → 계속 실행 가능
Kubernetes는 CronJob의 suspend가 이미 시작한 Job에 영향을 주지 않는다고 명시해. 따라서 CronJob을 멈췄어도 기존 Job이 DB를 수정하거나 PVC에 쓰고 있으면, 백업 시점의 쓰기 작업은 여전히 남아 있는 거야. �
kubernetes.io
점검 기준: CronJob SUSPEND=true만 보지 말고, 그 CronJob이 만든 미완료 Job과 해당 Pod까지 확인해야 해.
2-2. 기존 Job이 실패한 Pod를 다시 만들 수 있음
CronJob 스케줄러와 Job 컨트롤러는 별개야. Job은 성공 조건을 충족할 때까지 Pod를 재시도할 수 있고, Pod가 실패하거나 삭제되면 대체 Pod를 만들 수 있어. �
Kubernetes
그래서 이런 상황도 가능해.
CronJob suspend=true
        ↓
기존 Job은 아직 미완료
        ↓
그 Job의 Pod만 삭제
        ↓
Job 컨트롤러가 새 Pod 생성
“CronJob 멈췄는데 왜 Pod가 다시 생기지?”라면 먼저 Job의 owner 관계를 봐야 해. Pod만 반복해서 삭제하는 건 해결책이 아닐 수 있어.
참고로 Job 자체의 spec.suspend는 CronJob의 suspend와 다르게 활성 Pod를 종료시키는 동작이므로, 같은 의미로 생각하고 적용하면 안 돼. �
Kubernetes
2-3. concurrencyPolicy: Forbid는 전체 백업 중복 실행 방지 장치가 아님
Forbid는 동일한 CronJob이 만드는 Job 사이에만 적용돼. 다른 CronJob, 수동으로 실행한 cpd-cli, 별도 스케줄러가 시작한 작업까지 막아주지 않아. Replace는 이전 Job을 교체하므로, 백업 실행용 CronJob에 적용되어 있으면 진행 중 작업을 끊는 위험도 검토해야 해. �
kubernetes.io
즉, 아래가 각각 존재하면 충돌 여부를 따로 확인해야 해.
정기 백업 CronJob
수동 cpd-cli 백업
다른 운영 서버의 백업 스크립트
Velero Schedule
이 네 개를 하나의 CronJob에 설정한 Forbid로 통제할 수는 없어.
2-4. suspend를 해제하자마자 누락된 작업이 실행될 수 있음
특히 startingDeadlineSeconds가 설정되지 않은 CronJob은 재개 시 누락된 실행이 즉시 예약될 수 있어. 따라서 서비스가 아직 복구 중인데 CronJob부터 재개하면 maintenance·cleanup·배치 작업이 바로 시작하는 상황을 고려해야 해. �
kubernetes.io
내가 권하는 운영 순서는 다음이야.
백업 데이터 처리 종료 확인 → CPD posthook 및 서비스 상태 확인 → 원래 활성 상태였던 CronJob만 재개.
중지 이전부터 suspend=true였던 CronJob까지 일괄적으로 false로 바꾸면 안 돼.
2-5. 스케줄 시간과 실행 제한 시간을 혼동하는 문제
항목
의미와 주의점
.spec.timeZone
지정하지 않으면 컨트롤러의 시간대를 기준으로 스케줄을 해석해. 운영자가 생각한 한국 시간과 같은지 확인해야 해.
startingDeadlineSeconds
늦어진 스케줄을 언제까지 시작할 수 있는지에 대한 제한이야. 실행 중 Job의 최대 수행 시간이 아니야.
Job의 activeDeadlineSeconds
Job 실행 시간 제한 쪽 설정이야. 장시간 백업을 감싼 Job에 짧게 설정되어 있으면 작업 종료 원인이 될 수 있어.
앞의 두 항목은 CronJob, 마지막은 Job 설정이므로 구분해서 봐야 해. �
Kubernetes +1
2-6. cleanup-completed-resources는 CronJob 중지가 아님
IBM의 --cleanup-completed-resources는 완료된 Job·Pod를 정리하는 옵션이야. CronJob의 다음 실행을 막거나, 실행 중인 Job을 안전하게 종료하는 기능으로 보면 안 돼. �
IBM
따라서 아래는 서로 다른 작업이야.
완료된 Job/Pod 정리
예약된 실행 차단
기존 실행 작업 종료 확인
2-7. CronJob 목록에는 안 보이는 예약·유지보수 작업이 있음
Velero Schedule은 Kubernetes CronJob이 아닌 별도 CR이야. oc get cronjob만 확인하면 놓쳐. 또한 Velero 문서상 스케줄에서 수동 백업을 시작해도 다음 정기 실행 시각은 바뀌지 않으므로, 수동 작업과 정기 작업의 시간 중첩을 고려해야 해. �
Velero
그리고 Velero 1.14부터 repository maintenance를 별도 Kubernetes Job으로 실행하는 구조가 도입됐어. 이전 버전은 Velero 서버 Pod 내부에서 maintenance를 실행했기 때문에, 설치된 Velero 버전에 따라 점검 대상이 달라져. 이 Job을 CPD의 불필요한 배치라고 생각해서 일괄 삭제하면 안 돼. �
Velero
oc get schedules.velero.io -n <oadp-namespace>
oc get jobs.batch -n <oadp-namespace>
2-8. zen-rsi-evictor-cron-job은 존재 여부와 적용 버전을 구분해야 함
IBM 5.3.x Known Issues에는 zen-rsi-evictor-cron-job이 30분마다 RSI 패치가 필요한 Pod를 확인하고 미패치 Pod를 퇴거시키는 동작이 설명돼 있어. 한편 이 CronJob의 활성화 명령은 5.1.x 업그레이드 문서에서도 검색돼. �
IBM +1
따라서 정확한 정리는 이거야.
“5.1.3이니까 이 CronJob은 없다”도 단정하면 안 되고, “5.3 문서에 있으니까 5.1.3 Patch 12도 동일한 백업 결함에 걸린다”도 단정하면 안 돼.
실제 존재 여부, 현재 suspend 상태, 최근 실행 시각, 생성된 Job, 해당 패치 수준의 IBM 지침을 함께 확인해야 해.
2-9. 복원 후 CronJob이 너무 일찍 동작하는 위험
이건 특정 CPD 버그라고 확인된 것이 아니라, 활성 CronJob이 스케줄에 따라 Job을 생성한다는 Kubernetes 동작에서 도출되는 운영상 위험이야.
복원된 CronJob이 활성 상태이고 서비스 복구가 아직 진행 중이라면, 데이터 정리나 배치 작업이 준비되지 않은 서비스에 접근할 수 있어. 반대로 백업 당시의 중지 상태가 남아 있으면, 복원 후 정기 작업이 계속 멈춰 있을 수도 있어. 복원 완료 확인에 CronJob 상태 비교를 넣는 이유야. �
Kubernetes
CronJob 관리에서 내가 권하는 기준
서비스의 공식 백업 hook이 관리하는 대상인지 먼저 확인하고, 추가 통제가 필요한 CronJob만 대상으로 삼는 게 좋아. 이름에 cleanup, backup, maintenance가 들어간다는 이유만으로 중지 대상으로 확정하지는 말자.
운영 절차에는 원래 suspend 상태 보관 → 필요한 대상만 중지 → 미완료 Job 확인 → 백업·서비스 복구 확인 → 원래 상태로 복구를 넣는 것을 권해. 이는 위 동작을 고려한 운영 권고이고, IBM의 일괄 CronJob 중지 명령이라는 뜻은 아니야.
3. CronJob 외에, IBM 5.1.x에 문서화된 백업 실패 사례
아래는 백업 전에 확인할 항목과 오류 발생 시 확인 방향을 묶은 거야.
3-1. 사전 검사·서비스 정지·마운트 단계
문제
증상·조건
확인하거나 조치할 방향
백업용 ConfigMap 누락
global registry check failed, 특정 *-aux-*-cm이 not found. 업그레이드 이후나 수동 삭제 뒤 발생할 수 있음.
IBM은 해당 서비스 CR의 spec.last_br_recon 변경으로 reconciliation을 유도하는 방법을 안내해. 검사를 skip해서 숨길 문제가 아니야. �
IBM
서비스/리소스 정지 대기 timeout
timed out waiting for the condition. 종료 대기 중인 Pod 등의 상태를 확인해야 함.
어떤 리소스를 기다렸는지 로그에서 먼저 식별하고, 실제 종료가 느린 경우에 해당 대기 시간을 검토. 모든 timeout을 DPA 하나로 해결하지 않기. �
IBM
cpdbr-vol-mnt Pod 메모리 부족
오프라인 백업이 진행 중에 멈추거나 exit 137로 실패하는 IBM 사례.
IBM은 마운트 Pod 메모리 request/limit 조정을 안내해. Velero 메모리를 늘리는 것과 별개야. 실제 종료 이유가 OOMKilled인지 확인해야 해. �
IBM
이전 backup/checkpoint 작업이 진행 중이라고 판단됨
새 작업을 시작할 때 already in progress 계열 오류.
실제 진행 중인 작업과 비정상 종료 후 남은 상태를 먼저 구분. 프로세스 확인 없이 checkpoint reset부터 하지 않기. 이 유형은 IBM 5.1.x 문제해결 목록에 별도 항목으로 존재해. �
ibm.com
마운트 Pod가 시작되지 못함
cpdbr-vol-mnt의 생성·마운트가 지연되고 timeout.
Pod Events로 이미지 pull, 스케줄링, 볼륨 mount 문제를 분리. IBM 5.2.x의 관련 문서는 높은 부하에서 CRI-O의 volume 설정·컨테이너 생성 지연을 설명해. 이 상세 조건은 5.2.x에서 확인한 것이야. �
IBM
특히 ConfigMap 누락은 “백업 기능 자체가 덜 준비된 상태”일 수 있어
예를 들어 IBM 문서에는 다음처럼 백업용 ConfigMap을 찾지 못하는 사례가 나와.
cpd-ikc-ccs-aux-ckpt-cm not found
이때 단순히 ConfigMap 이름 하나를 만들어 넣거나 --skip-hooks로 통과시키는 방식보다, 해당 서비스가 제공해야 하는 백업 구성이 제대로 생성되도록 복구하는 것이 우선이야. �
IBM
3-2. S3·BSL·인증 관련
문제
증상·조건
확인하거나 조치할 방향
BackupStorageLocation이 Unavailable
백업 대상 저장소 검증 실패.
BSL 상태·메시지, 실제 bucket, endpoint, credential 설정 확인. Available은 기본 점검 항목이지 전체 백업 성공 보장은 아님. �
ibm.com
Bucket이 존재하지 않음
bucket does not exist.
DPA/BSL에 적힌 bucket과 실제 저장소의 bucket이 일치하는지 확인. IBM 5.1.x에 별도 문제해결 항목이 있어. �
IBM
S3 인증서 오류
S3 연결 과정의 certificate 오류.
저장소 인증서·신뢰 설정 확인 대상. 운영 환경에서 검증 해제를 기본 해결책으로 삼지 않기. IBM 목록에 별도 사례가 존재하고, CLI 문서도 insecure 옵션의 운영 사용을 권장하지 않아. �
IBM +1
MinIO request signature 오류
The request signature we calculated does not match....
IBM의 특정 MinIO 사례는 credential 문제를 다루며 영숫자 credential 사용을 안내해. S3 전체에서 특수문자가 금지된다는 뜻은 아니야. �
IBM
MinIO에서 NoSuchKey
백업 로그나 velero-backup.json 업로드 과정에서 specified key 오류.
bucket·credential 파일·DPA 설정 확인. 앞쪽 로그에 Backup completed가 있더라도 뒤의 메타데이터 업로드 오류를 봐야 해. �
IBM
로그 조회만 SignatureDoesNotMatch
백업 데이터 처리와 별개로 로그 다운로드가 실패할 수 있음.
Velero는 임시 서명 URL을 사용하므로 S3 호환 구현의 서명 처리도 확인 대상이야. “로그 조회 실패=볼륨 백업 실패”로 바로 등치시키면 안 돼. �
Velero
실무적으로는 “S3 접속된다”를 한 번 확인하는 것보다, 해당 백업이 필요한 데이터와 메타데이터를 실제로 저장하고 다시 읽을 수 있는지까지 확인하는 게 중요해. IBM도 별도 S3 클라이언트를 이용한 읽기·쓰기 확인을 기본 진단에 포함해. �
ibm.com
3-3. Restic repository·데이터 전송·메모리 관련
문제
증상·조건
확인하거나 조치할 방향
Repository lock
repository is already locked. IBM 5.1.x 공식 항목.
다른 백업·복원·maintenance 작업이 실제로 사용 중인지 먼저 확인. 중단된 작업의 잔여 lock인지 구분한 뒤 지원 절차로 처리해야 해. �
IBM +1
Repository config object가 사라짐
unable to open config file, specified key does not exist.
IBM은 object storage의 Restic 디렉터리를 지웠는데 repository CR은 남은 경우를 설명해. 저장소 파일과 Kubernetes 상태가 불일치한 문제야. �
IBM
Repository pruning 중 실패
error pruning repository, Velero OOMKilled.
IBM은 Velero/node-agent 메모리 설정을 검토하도록 안내해. 예시 수치를 그대로 넣기보다 실제 사용량·노드 여유·quota와 맞춰야 해. �
IBM
PodVolumeBackup/Restore timeout
볼륨 데이터 처리 완료 대기 timeout.
IBM이 제시하는 관련 설정은 DPA의 spec.configuration.nodeAgent.timeout. scale 대기와 별개야. �
IBM
백업 중 Velero 또는 대상 Pod 재시작
InProgress에서 멈춰 보임.
Velero 1.14 문서는 중단된 백업을 자동으로 이어서 처리하지 못하는 경우를 설명해. 재시작만으로 정상 완료될 거라고 기대하면 안 돼. �
Velero
Repository maintenance가 리소스를 소모
backup과 maintenance가 겹치는 시간대에 CPU·메모리 부담.
Velero 버전에 따라 서버 Pod 내부 또는 별도 Job을 조사. node-agent만 보지 말고 maintenance 실행 주체도 확인. �
Velero
Repository 비밀번호를 뒤늦게 변경
기존 백업 repository에 접근하지 못함.
Velero는 첫 백업으로 repository를 만든 뒤 velero-repo-credentials의 비밀번호를 바꾸면 이전 백업에 연결하지 못할 수 있다고 경고해. S3 접근 키와 repository 비밀번호를 혼동하지 말아야 해. �
Velero
저장소가 꼬였을 때 특히 하면 안 되는 것
“다시 백업하면 되겠지” 하고 bucket 안의 Restic/Kopia 데이터를 수동으로 정리하는 건 위험해.
IBM은 repository 파일 수동 삭제 후 CR과의 불일치 사례를 문서화했고, Restic도 repository 파일 손실·삭제가 손상 원인이 될 수 있다고 설명해. 복구 작업 전에는 가능한 한 원본 repository를 보존하고, 추가 변경 작업을 통제하는 절차가 필요해. �
IBM +1
그래서 아래는 원인 확인 전에 일괄 실행할 명령이 아니야.
bucket 내부 파일 삭제
repository CR 전체 삭제
강제 unlock
checkpoint reset
finalizer 강제 제거
오류 메시지가 같아도 “현재 작업 중인 잠금”과 “죽은 작업의 잠금”, “인증 실패”와 “실제 object 손실”은 처리가 달라.
4. NFS 환경에서 별도로 봐야 하는 문제
4-1. EFS 전용 이슈를 일반 NFS 문제로 확대하면 안 됨
IBM Known Issues에는 동적으로 프로비저닝한 Amazon EFS 볼륨을 포함한 Restic 백업이 복원에서 실패하는 항목이 있어. 하지만 일반 NFS라는 사실만으로 동일한 EFS 결함에 해당한다고 볼 수는 없어. �
IBM
따라서 네 환경에서는 먼저 실제 provisioner와 백업 방식을 확인하고 판단해야 해. “NFS니까 무조건 Kopia로 바꾸자”라는 결론은 아직 근거가 부족해.
4-2. 읽기는 되는데 복원 시 파일 생성·소유권 처리가 실패할 수 있음
일반 NFS에서도 권한은 별도 점검 대상이야. NFS 서버는 root_squash 설정에 따라 클라이언트의 root 접근을 nobody로 매핑할 수 있어. 따라서 컨테이너 안에서 root라고 해서 NFS 서버에서도 같은 권한을 갖는 건 아니야. �
레드햇 문서
이 동작을 고려하면, 다음 오류에서는 백업 프로그램뿐 아니라 NFS export와 UID/GID·디렉터리 권한을 함께 조사해야 해.
Permission denied
Operation not permitted
chown / lchown 관련 실패
파일 또는 디렉터리 생성 실패
백업 읽기 성공과 복원 쓰기·권한 복구 성공을 별도 테스트하는 것을 권해. 그렇다고 원인 확인 없이 모든 export에 no_root_squash를 적용하라는 뜻은 아니야.
4-3. PVC가 존재한다고 실제 파일이 백업되는 건 아님
Velero FSB는 Pod에 마운트된 파일시스템을 통해 데이터를 읽어. Pod에 마운트되지 않은 PVC는 별도 준비 없이 동일하게 백업할 수 없고, CPD의 마운트 Pod가 정상적으로 준비되었는지도 중요해. �
Velero
따라서 확인해야 할 것은 단순한 PVC 개수가 아니라 다음 관계야.
백업 대상 PVC
   → 어느 Pod/볼륨으로 마운트되었는가
   → 해당 데이터 백업 작업이 생성되었는가
   → 그 작업이 완료되었는가
4-4. NFS 용량만 보고 백업 시간을 예상하면 빗나갈 수 있음
Velero 문서는 큰 파일은 변경량이 작더라도 중복 제거를 위한 스캔 시간이 오래 걸릴 수 있다고 설명해. 특히 DB 파일은 “이번에 바뀐 데이터가 얼마 안 되니까 금방 끝날 것”이라고 단정하기 어려워. �
Velero
운영 측면에서는 총 용량 외에 파일 구성, NFS 응답, 같은 시간대의 다른 I/O, 실제 전송 진행률을 함께 보는 게 좋아.
4-5. CPD 외부에서도 같은 파일을 수정한다면 정합성 범위를 다시 봐야 함
FSB는 한순간을 고정한 스냅샷이 아니라 실행 중인 파일시스템을 읽는 방식이야. 따라서 CPD 서비스를 정지했더라도, 별도 시스템이 같은 경로를 계속 수정한다면 일관된 백업 시점이라는 전제가 깨질 수 있어. 이는 FSB 동작에서 도출되는 운영상 위험이야. �
Velero
CPD Pod가 내려갔는지뿐 아니라, 백업 대상 데이터에 쓰는 다른 주체가 있는지도 확인할 것을 권해.
5. “백업은 성공했는데 복원이 실패하는” 문제들
이 부분은 백업 전에 알아둬야 해. 장애가 난 뒤에 처음 확인하면 복구 시간이 길어질 수 있으니까.
5-1. IBM 5.1.x에 문서화된 복원 사례
문제
IBM 문서의 원인·증상
중요한 대응 구분
오프라인 restore posthook이 일부만 성공
Posthook Status: partially_succeeded, post-processing 오류.
해당 사례에서 IBM은 restore posthook 재실행을 안내해. 데이터 복원 전체를 무조건 처음부터 다시 하는 문제와 구분해야 해. �
IBM
lite-cr가 복원되지 않음
zenservices... "lite-cr" not found, cpd-lite-aux-br-cm posthook 오류.
누락된 zenService 복원 단계가 문제. timeout을 늘려도 없는 CR이 생기지는 않아. �
IBM
Create OperandRequest Timeout
복원이 오래 진행된 뒤 실패.
IBM은 ODLM이 instance namespace의 Role/RoleBinding을 설치하지 못한 경우를 주요 원인으로 설명해. operator·instance namespace의 OperandRequest 상태를 함께 확인. �
IBM
Db2U StatefulSet이 Ready가 되지 않음
c-db2oltp-wkc-db2u가 0/1, Pod 생성 Forbidden, SCC 검증 실패.
오래된 SCC가 원인인 공식 사례가 있어. 백업 데이터나 NFS 속도 문제가 아니라 보안 정책 잔재일 수 있음. �
IBM
OpenSearch Pod가 Ready가 되지 않음
인덱스가 red, Pod 반복 시작, shard 문제.
IBM은 큰 인덱스 복구의 대기 시간 문제와 실제 shard 손상을 구분해. 손상이면 timeout 증가만으로 해결되지 않고 snapshot 복구·재인덱싱 등 별도 판단이 필요해. �
IBM
주의: 위 문서 중에는 namespace나 SCC 정리 후 재복원을 안내하는 경우가 있어. 그 명령은 복원 대상과 정리 범위를 확정한 뒤 적용해야 해. 운영 중인 원본 클러스터에서 그대로 복사해 실행할 내용은 아니야.
5-2. 기존 리소스가 남아 있어서 “복원한 줄 알았는데 안 바뀌는” 문제
Velero의 기본 복원 동작은 기존 리소스를 무조건 덮어쓰지 않아. 대상 리소스가 이미 존재하면 건너뛰는 동작이 있고, existing-resource-policy=update도 PVC 내부 데이터를 덮어쓰는 기능은 아니야. �
Velero
그래서 다음 생각은 위험해.
“기존 CPD와 PVC가 그대로 있어도 restore를 한 번 실행하면 백업 시점으로 싹 돌아가겠지.”
CPD의 동일 클러스터 복원 절차에서 무엇을 남기고 무엇을 정리하는지를 따라야 해.
5-3. API·CRD·admission webhook 때문에 리소스가 복원되지 않는 문제
Velero는 복원할 리소스의 API를 대상 클러스터에서 발견하지 못하면 복원 대상에서 제외할 수 있어. 또 admission webhook이 리소스 생성을 차단하거나 변경하면 예상하지 못한 복원 실패가 발생할 수 있어. �
Velero +1
이 때문에 다른 클러스터로 복원할 때는 OCP·Operator·CRD·보안 설정을 데이터 백업과 별개로 맞춰야 하는 부분이 있어. “S3에 데이터 있으니 아무 클러스터에나 복원된다”는 방식으로 접근하면 안 돼.
5-4. Pending이라고 전부 장애는 아님
StorageClass가 WaitForFirstConsumer라면 소비할 Pod가 준비될 때까지 PVC 바인딩·프로비저닝을 미룰 수 있어. 반대로 스케줄링 조건이 맞지 않으면 그 단계에서 계속 막힐 수도 있어. PVC 상태와 그것을 사용할 Pod의 Events를 같이 봐야 해. �
Kubernetes
따라서 앞서 내가 제시했던 grep Pending 같은 명령은 후보를 찾는 용도이지, 나온 것을 전부 장애로 판정하는 명령은 아니야.
6. 백업 “누락”과 보관·삭제 문제도 별도로 확인해야 해
6-1. 필터·라벨 때문에 필요한 리소스가 빠지는 문제
Velero는 namespace, resource type, label selector, resource policy 등으로 대상을 제한할 수 있어. 특히 다음 라벨이 있으면 selector에 맞더라도 제외될 수 있어.
velero.io/exclude-from-backup: "true"
따라서 백업 실패 오류가 없더라도 원래 의도한 리소스가 필터 때문에 빠진 것은 아닌지 확인해야 해. �
Velero
Completed는 “선택된 작업을 완료했다”는 뜻으로 읽어야지, “내가 필요로 하는 모든 것을 선택했다”는 증거로 읽으면 안 돼.
6-2. 백업 CR 삭제와 저장소 데이터 삭제를 혼동하는 문제
Velero 문서는 Kubernetes에서 Backup CR만 삭제하는 것과 Velero의 백업 삭제 작업을 구분해. 삭제 방식에 따라 object storage에 관련 데이터가 남을 수 있어. CPD에서는 해당 버전의 tenant/backup 삭제 절차를 기준으로 정리해야 해. �
Velero
IBM 5.1.x에는 백업이 계속 Deleting 상태로 남는 문제도 별도 문제해결 항목으로 실려 있어. 그래서 Deleting을 보고 곧바로 finalizer를 제거하거나 bucket을 지우는 방식은 피해야 해. �
ibm.com
6-3. GitOps나 owner reference로 Backup CR이 반복 삭제되는 문제
Velero 문서에는 Schedule과 Backup 사이에 owner reference를 설정한 경우, Schedule 삭제에 따라 Backup CR이 garbage collection되고, 저장소 동기화가 이를 다시 만들어 삭제·재생성이 충돌하는 상황이 설명돼 있어. GitOps가 백업 리소스를 관리한다면 이 관계도 확인 대상이야. �
Velero
6-4. 보관 기간과 object storage 정책이 서로 다른 문제
내가 권하는 점검은 CPD/Velero의 보관 기간과 object storage 쪽 삭제·보존 정책을 함께 대조하는 것이야. 특히 repository 내부 object가 별도 정책이나 수동 작업으로 없어지면, Kubernetes에 Backup 항목이 남아 있다고 해서 데이터를 복구할 수 있는 것은 아니야. 파일 손실이 repository 손상 원인이라는 점은 Restic 문서에도 명시돼 있어. �
Restic Documentation
7. 조건이 달라서 별도로 분류해야 하는 추가 공식 항목
아래는 IBM 5.1.x OADP 문제해결 목록에서 존재를 확인한 항목들이야. 다만 이번에 모든 개별 본문과 Patch 12 수정 여부까지 확인한 것은 아니므로, 해결 방법을 임의로 붙이지 않았어. 온라인 전용·스토리지 전용 이슈를 네 오프라인 NFS 환경의 확정 결함으로 섞으면 안 돼. �
ibm.com
적용 조건
추가 확인할 공식 문제
온라인 백업/복원
Knowledge Catalog glossary가 올바르게 복원되지 않는 문제, Data Privacy masking flow job이 복원 후 시작되지 않는 문제
온라인 백업/복원
PVC가 Bound가 되지 않는 문제, 일부 작업이 timeout으로 PartiallyFailed가 되는 문제
온라인 백업/복원
이전 작업의 in-progress 상태 때문에 다음 작업이 실행되지 않는 문제
Watson Studio의 기존 Git 프로젝트
온라인 복원 후 동기화되지 않는 문제
IBM Storage Scale
실패한 온라인 복원 후 PVC 파일이 남는 문제
AWS 관련 환경
cpdbr-vol-mnt Pod가 Pending으로 남는 문제
Snapshot 방식
최대 snapshot 개수 관련 오류
복원 대상·저장소
Backup not found, 복원 리소스 누락
이 항목들은 해당 서비스나 방식이 실제로 포함될 때 추가 조사할 목록이야. 예를 들어 일반 NFS의 파일 백업을 쓰는데 AWS snapshot 한도부터 조정하는 건 방향이 잘못된 거지.
8. timeout은 이렇게 구분해야 해
앞서 물어본 resourceTimeout도 이 구분 안에서 판단해야 해.
설정
관련 대기
판단 기준
cpd-cli ... --scale-wait-timeout
서비스 scale 관련 대기
IBM 5.1.x 명령 참조는 기본 30m0s. 설치된 CLI 확인 필요. �
IBM
DPA spec.configuration.nodeAgent.timeout
Pod volume 백업·복원 처리 대기
IBM의 Pod volume timeout 문제해결에서 조정하는 항목. 문서 예시값을 전체 환경의 기본값으로 보면 안 됨. �
IBM
DPA spec.configuration.velero.resourceTimeout
별도의 전용 timeout으로 다루지 않는 리소스 처리 대기
Red Hat 문서는 기본 10분으로 설명하지만, 설치된 OADP 버전과 스키마를 확인해야 함. 전체 CPD 백업 시간 제한이 아님. �
레드햇 문서
서비스 hook·Job 자체의 제한
특정 hook 또는 Job 수행
해당 hook 로그와 Job 설정을 조사해야 함. 다른 계층의 timeout을 늘려도 직접 해결되지 않을 수 있음. �
IBM +1
이런 문제는 timeout을 늘리는 것으로 해결되지 않아.
존재하지 않는 bucket
잘못된 credential
누락된 lite-cr / 백업 ConfigMap
SCC 때문에 Forbidden인 Pod
계속 재생성되는 쓰기 작업
삭제된 repository object
반대로 실제 데이터 전송이나 정상적인 복구가 진행 중이고, 측정된 소요 시간이 제한을 넘는 경우라면 해당 계층의 timeout 증가를 검토할 수 있어.
9. 네 환경에서 실행해 볼 읽기 전용 점검 명령
아래는 조회용이야. NS, OPNS, OADP는 해당 사이트의 실제 값으로 넣어. 이전 출력의 zen, oadp-operator를 다른 사이트에도 자동으로 적용하면 안 돼.
NS="<CPD instance namespace>"
OPNS="<CPD operator namespace>"
OADP="<OADP namespace>"
9-1. 버전·DPA·저장소·현재 작업
oc version
cpd-cli version
cpd-cli oadp version

oc get csv -n "$OADP"
oc get sc

oc get dpa -n "$OADP" -o yaml
oc get backupstoragelocations.velero.io -n "$OADP"

oc get backups.velero.io -n "$OADP"
oc get restores.velero.io -n "$OADP"

oc get schedules.velero.io -n "$OADP"
oc get backuprepositories.velero.io -n "$OADP"
oc get jobs.batch -n "$OADP"
버전·StorageClass·BSL 확인은 IBM 기본 진단 항목이고, repository·volume 작업은 Velero 진단 대상이야. 리소스 종류가 없다는 오류는 버전·설치 구성 차이일 수 있으므로, 빈 목록과 구분해야 해. �
IBM +1
9-2. CronJob 상태를 정확히 조회
앞서 내가 .status.active를 숫자처럼 설명한 부분도 수정할게. CronJob의 status.active는 참조 목록이므로 개수를 세어야 해. 아래는 jq가 필요해.
oc get cronjobs.batch -n "$NS" -o json |
jq -r '
  ["NAME","SUSPEND","ACTIVE_COUNT","SCHEDULE","TIMEZONE","POLICY","LAST"],
  (.items[] | [
    .metadata.name,
    (.spec.suspend // false),
    ((.status.active // []) | length),
    .spec.schedule,
    (.spec.timeZone // "<controller timezone>"),
    (.spec.concurrencyPolicy // "Allow"),
    (.status.lastScheduleTime // "-")
  ])
  | @tsv
'
각 항목은 CronJob API의 spec/status를 읽는 거야. 필요한 경우 operator namespace에도 같은 조회를 반복하면 돼. �
Kubernetes
9-3. ACTIVE=0이어도 미완료인 Job까지 확인
아래는 Complete 또는 Failed의 최종 조건이 아직 붙지 않은 Job을 찾는 조회야. 재시도 대기 중이라 현재 활성 Pod가 없는 경우를 놓치지 않기 위한 거야. Job은 Pod 재시도와 최종 완료 상태를 별도로 관리해. �
Kubernetes
oc get jobs.batch -n "$NS" -o json |
jq -r '
  ["NAME","OWNER","ACTIVE","SUCCEEDED","FAILED","START"],
  (.items[]
   | select(
       ([.status.conditions[]?
         | select(
             (.type == "Complete" or .type == "Failed")
             and .status == "True"
           )
        ] | length) == 0
     )
   | [
       .metadata.name,
       ((.metadata.ownerReferences // [])
         | map(.kind + "/" + .name) | join(",")),
       (.status.active // 0),
       (.status.succeeded // 0),
       (.status.failed // 0),
       (.status.startTime // "-")
     ])
  | @tsv
'
여기 나온 Job은 삭제 목록이 아니라 조사 목록이야. owner와 수행 내용을 확인해야 해.
9-4. 볼륨별 결과와 Pod 상태
oc get podvolumebackups.velero.io -n "$OADP" \
  -o custom-columns='NAME:.metadata.name,NS:.spec.pod.namespace,POD:.spec.pod.name,VOLUME:.spec.volume,PHASE:.status.phase,MESSAGE:.status.message'

oc get podvolumerestores.velero.io -n "$OADP"

oc get pods -n "$NS" -o wide
oc get pvc -n "$NS"

oc get pods -n "$OADP" -o wide
oc get daemonsets -n "$OADP"

oc get events -n "$NS" --sort-by=.metadata.creationTimestamp
oc get events -n "$OADP" --sort-by=.metadata.creationTimestamp
FSB 방식에서는 대상 Backup에 연결된 PodVolumeBackup/Restore 결과를 확인해야 해. CSI snapshot·data mover 등 다른 방식을 사용하면 필요한 확인 리소스가 달라지므로, PVB가 없다는 사실만으로 실패라고 판단하지는 마. �
Velero
문제가 생긴 Pod는 다음으로 좁혀 보면 돼.
oc describe pod <problem-pod> -n <namespace>
oc logs <problem-pod> -n <namespace> -c <container>
oc logs <problem-pod> -n <namespace> -c <container> --previous
현재 로그만 보면 재시작 전에 발생한 OOM·실패 원인을 놓칠 수 있으니, 종료 상태와 이전 컨테이너 로그도 함께 보는 것을 권해.
10. 이번 백업에서 적용할 완료 판정 기준
내가 운영 점검표를 만든다면, 완료 조건을 다음 세 묶음으로 잡겠어.
백업 준비: 버전과 실행 모드가 맞고, 필요한 백업 ConfigMap과 사전 검사가 통과했으며, 의도하지 않은 쓰기 Job이 남아 있지 않을 것.
백업 결과: tenant 작업 결과뿐 아니라 실제 생성된 Backup과 해당 볼륨 데이터 작업이 정상 종료했고, 필요한 리소스가 필터로 빠지지 않았으며, 저장소의 관련 데이터·메타데이터를 읽을 수 있을 것.
운영 복귀·복구 가능성: posthook이 성공하고 서비스가 정상화됐으며, CronJob이 원래 상태로 돌아왔고, 별도 복원 검증으로 실제 복구 가능성을 확인할 것. 이 기준은 위의 IBM hook 실패 사례와 Velero의 볼륨별 확인·필터링 동작을 고려한 운영 권고야. �
IBM +3
네 환경에서 우선적으로 보겠다는 것은 resourceTimeout 일괄 증가가 아니라, CronJob + 미완료 Job, 백업용 ConfigMap, cpdbr-vol-mnt, BSL/repository, 볼륨별 결과, posthook 상태야.
마지막으로 조사 범위는 분명히 할게. IBM 5.1.x OADP 문제해결 목록과 여러 개별 본문, Kubernetes·Velero·Red Hat의 관련 동작을 확인했지만, IBM Known Issues 일부 페이지는 접근 오류로 전체 본문을 읽지 못했고 Patch 12별 수정 여부도 전부 교차 검증하지 못했어. 그래서 위 내용을 “Patch 12에서 현재 발생하는 모든 확정 버그”라고 부르지는 않을게. 대신 공식 사례·일반 동작·조건부 위험을 구분한 사전 점검 및 장애 분석 목록으로 쓰는 게 정확해.
