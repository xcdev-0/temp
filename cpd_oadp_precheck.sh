#!/usr/bin/env bash
# CPD / IBM Software Hub OADP pre-backup preflight checker
# Read-only: this script does NOT patch/delete/reset/unlock anything.
# Requires: oc, jq

set -uo pipefail

CPD_NS="${CPD_NS:-${PROJECT_CPD_INST_OPERANDS:-}}"
CPD_OP_NS="${CPD_OP_NS:-${PROJECT_CPD_INST_OPERATORS:-}}"
OADP_NS="${OADP_NS:-${OADP_OPERATOR_PROJECT:-}}"
SCAN_LOGS=0
LOG_TAIL=800

usage() {
  cat <<'USAGE'
Usage:
  ./cpd_oadp_precheck.sh -c <cpd-instance-ns> -o <oadp-ns> [-p <cpd-operator-ns>] [--logs] [--log-tail N]

The script also accepts IBM environment variables if already exported:
  PROJECT_CPD_INST_OPERANDS
  PROJECT_CPD_INST_OPERATORS
  OADP_OPERATOR_PROJECT

Examples:
  ./cpd_oadp_precheck.sh -c zen -p cpd-operators -o oadp-operator
  ./cpd_oadp_precheck.sh -c zen -o oadp-operator --logs
  ./cpd_oadp_precheck.sh --logs   # when the IBM variables above are already set

Read-only checks include:
  - OCP / OADP / cpd-cli versions and client config
  - DPA status and Velero/node-agent resources/timeouts
  - Velero 4Gi and node-agent 32Gi memory-limit reference checks
  - BSL availability
  - BackupRepository / ResticRepository state
  - active/in-progress Backup/Restore objects
  - OADP pod restarts/OOMKilled and node-agent DaemonSet readiness
  - CronJobs, known RSI evictor, and unfinished/failed Jobs
  - terminating/unhealthy CPD pods and cpdbr-vol-mnt OOM/restarts
  - PVC status / StorageClass / PV backend type
  - ResourceQuota / LimitRange in the OADP namespace
  - recent Warning events
  - optional Velero/node-agent log pattern scan

No Secret contents are printed.
USAGE
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -c|--cpd-ns) CPD_NS="${2:-}"; shift 2 ;;
    -p|--cpd-operator-ns) CPD_OP_NS="${2:-}"; shift 2 ;;
    -o|--oadp-ns) OADP_NS="${2:-}"; shift 2 ;;
    --logs) SCAN_LOGS=1; shift ;;
    --log-tail) LOG_TAIL="${2:-800}"; shift 2 ;;
    -h|--help) usage; exit 0 ;;
    *) echo "Unknown argument: $1" >&2; usage; exit 2 ;;
  esac
done

if ! command -v oc >/dev/null 2>&1; then
  echo "ERROR: oc command not found" >&2
  exit 2
fi
if ! command -v jq >/dev/null 2>&1; then
  echo "ERROR: jq command not found" >&2
  exit 2
fi
if ! oc whoami >/dev/null 2>&1; then
  echo "ERROR: oc is not logged in to a cluster" >&2
  exit 2
fi

# Try a safe DPA-based OADP namespace autodetect if not supplied.
if [[ -z "$OADP_NS" ]]; then
  mapfile -t _dpa_ns < <(oc get dpa.oadp.openshift.io -A -o json 2>/dev/null | jq -r '.items[].metadata.namespace' | sort -u)
  if [[ ${#_dpa_ns[@]} -eq 1 ]]; then
    OADP_NS="${_dpa_ns[0]}"
  fi
fi

if [[ -z "$CPD_NS" || -z "$OADP_NS" ]]; then
  echo "ERROR: CPD namespace and OADP namespace are required." >&2
  echo "       Use -c/-o or export PROJECT_CPD_INST_OPERANDS and OADP_OPERATOR_PROJECT." >&2
  exit 2
fi

PASS=0
WARN=0
FAIL=0

section() { printf '\n\n========== %s ==========\n' "$*"; }
info()    { printf '[INFO] %s\n' "$*"; }
pass()    { PASS=$((PASS+1)); printf '[PASS] %s\n' "$*"; }
warn()    { WARN=$((WARN+1)); printf '[WARN] %s\n' "$*"; }
fail()    { FAIL=$((FAIL+1)); printf '[FAIL] %s\n' "$*"; }

has_api() {
  oc api-resources -o name 2>/dev/null | grep -Fxq "$1"
}

mem_to_mi() {
  # Kubernetes memory quantity -> approximate MiB. Supports raw bytes, Ki/Mi/Gi/Ti and k/M/G/T.
  awk -v q="$1" 'BEGIN {
    if (q == "" || q == "null" || q == "<unset>") { print -1; exit }
    if (q ~ /^[0-9]+(\.[0-9]+)?Ki$/) { sub(/Ki$/, "", q); printf "%.0f", q/1024; exit }
    if (q ~ /^[0-9]+(\.[0-9]+)?Mi$/) { sub(/Mi$/, "", q); printf "%.0f", q; exit }
    if (q ~ /^[0-9]+(\.[0-9]+)?Gi$/) { sub(/Gi$/, "", q); printf "%.0f", q*1024; exit }
    if (q ~ /^[0-9]+(\.[0-9]+)?Ti$/) { sub(/Ti$/, "", q); printf "%.0f", q*1024*1024; exit }
    if (q ~ /^[0-9]+(\.[0-9]+)?k$/)  { sub(/k$/,  "", q); printf "%.0f", q*1000/1048576; exit }
    if (q ~ /^[0-9]+(\.[0-9]+)?M$/)  { sub(/M$/,  "", q); printf "%.0f", q*1000000/1048576; exit }
    if (q ~ /^[0-9]+(\.[0-9]+)?G$/)  { sub(/G$/,  "", q); printf "%.0f", q*1000000000/1048576; exit }
    if (q ~ /^[0-9]+(\.[0-9]+)?T$/)  { sub(/T$/,  "", q); printf "%.0f", q*1000000000000/1048576; exit }
    if (q ~ /^[0-9]+$/) { printf "%.0f", q/1048576; exit }
    print -2
  }'
}

check_ns() {
  local ns="$1" label="$2"
  if oc get ns "$ns" >/dev/null 2>&1; then
    pass "$label namespace exists: $ns"
  else
    fail "$label namespace not found or not readable: $ns"
  fi
}

section "INPUT"
info "CPD instance namespace : $CPD_NS"
info "CPD operator namespace : ${CPD_OP_NS:-<not supplied>}"
info "OADP namespace         : $OADP_NS"
info "Log scan              : $SCAN_LOGS (tail=$LOG_TAIL lines/container)"

section "NAMESPACE / ACCESS"
check_ns "$CPD_NS" "CPD instance"
[[ -n "$CPD_OP_NS" ]] && check_ns "$CPD_OP_NS" "CPD operator"
check_ns "$OADP_NS" "OADP"

for r in pods jobs.batch cronjobs.batch persistentvolumeclaims; do
  if oc auth can-i list "$r" -n "$CPD_NS" 2>/dev/null | grep -qx yes; then
    pass "Can list $r in $CPD_NS"
  else
    warn "Cannot list $r in $CPD_NS; some checks will be incomplete"
  fi
done

section "VERSIONS / CLIENT CONFIG"
oc version 2>/dev/null || warn "Unable to read OpenShift version"

echo
info "OADP CSV(s):"
oc get csv -n "$OADP_NS" 2>/dev/null || warn "Unable to list CSVs in $OADP_NS"

if [[ -n "$CPD_OP_NS" ]]; then
  echo
  info "CPD/zen CSV(s):"
  oc get csv -n "$CPD_OP_NS" 2>/dev/null | grep -Ei 'zen|cpd|ibm' || info "No matching CSV shown"
fi

if command -v cpd-cli >/dev/null 2>&1; then
  echo
  cpd-cli version 2>/dev/null || true
  cpd-cli oadp version 2>/dev/null || true
  echo
  info "cpd-cli OADP client config:"
  cpd-cli oadp client config get 2>/dev/null || warn "Unable to read cpd-cli OADP client config"
else
  warn "cpd-cli not found; CLI version/client-config checks skipped"
fi

section "DPA CONFIGURATION"
if ! has_api 'dataprotectionapplications.oadp.openshift.io'; then
  fail "DataProtectionApplication API not found"
else
  DPA_JSON="$(oc get dpa -n "$OADP_NS" -o json 2>/dev/null || echo '{"items":[]}')"
  DPA_COUNT="$(jq '.items|length' <<<"$DPA_JSON")"
  if [[ "$DPA_COUNT" -eq 0 ]]; then
    fail "No DPA found in $OADP_NS"
  else
    [[ "$DPA_COUNT" -gt 1 ]] && warn "Multiple DPAs found ($DPA_COUNT); review each one"
    while IFS= read -r dpa_name; do
      [[ -z "$dpa_name" ]] && continue
      echo
      info "DPA: $dpa_name"
      DPA_ONE="$(oc get dpa "$dpa_name" -n "$OADP_NS" -o json 2>/dev/null)"

      vel_mem="$(jq -r '.spec.configuration.velero.podConfig.resourceAllocations.limits.memory // "<unset>"' <<<"$DPA_ONE")"
      vel_req="$(jq -r '.spec.configuration.velero.podConfig.resourceAllocations.requests.memory // "<unset>"' <<<"$DPA_ONE")"
      node_enabled="$(jq -r '.spec.configuration.nodeAgent.enable // false' <<<"$DPA_ONE")"
      uploader="$(jq -r '.spec.configuration.nodeAgent.uploaderType // "<unset>"' <<<"$DPA_ONE")"
      node_mem="$(jq -r '.spec.configuration.nodeAgent.podConfig.resourceAllocations.limits.memory // "<unset>"' <<<"$DPA_ONE")"
      node_req="$(jq -r '.spec.configuration.nodeAgent.podConfig.resourceAllocations.requests.memory // "<unset>"' <<<"$DPA_ONE")"
      node_timeout="$(jq -r '.spec.configuration.nodeAgent.timeout // "<unset>"' <<<"$DPA_ONE")"
      resource_timeout="$(jq -r '.spec.configuration.velero.resourceTimeout // "<unset>"' <<<"$DPA_ONE")"

      info "Velero memory request/limit : $vel_req / $vel_mem"
      info "Velero resourceTimeout      : $resource_timeout"
      info "NodeAgent enabled/uploader  : $node_enabled / $uploader"
      info "NodeAgent memory req/limit  : $node_req / $node_mem"
      info "NodeAgent timeout           : $node_timeout"

      vel_mi="$(mem_to_mi "$vel_mem")"
      if [[ "$vel_mi" =~ ^-?[0-9]+$ ]] && (( vel_mi >= 0 )); then
        if (( vel_mi < 4096 )); then
          warn "Velero memory limit is below IBM 5.1.x troubleshooting example 4Gi: $vel_mem"
        else
          pass "Velero memory limit is at least 4Gi: $vel_mem"
        fi
      else
        warn "Could not evaluate Velero memory limit: $vel_mem"
      fi

      if [[ "$node_enabled" == "true" ]]; then
        node_mi="$(mem_to_mi "$node_mem")"
        if [[ "$node_mi" =~ ^-?[0-9]+$ ]] && (( node_mi >= 0 )); then
          if (( node_mi < 32768 )); then
            warn "NodeAgent memory limit is below IBM troubleshooting example 32Gi: $node_mem"
          else
            pass "NodeAgent memory limit is at least 32Gi: $node_mem"
          fi
        else
          warn "Could not evaluate NodeAgent memory limit: $node_mem"
        fi
      else
        info "NodeAgent is disabled in this DPA; filesystem-backup checks may not apply to this DPA"
      fi

      info "DPA conditions:"
      jq -r '.status.conditions[]? | "  - \(.type): \(.status) reason=\(.reason // "-") message=\(.message // "-")"' <<<"$DPA_ONE"
    done < <(jq -r '.items[].metadata.name' <<<"$DPA_JSON")
  fi
fi

section "OADP RESOURCEQUOTA / LIMITRANGE"
oc get resourcequota,limitrange -n "$OADP_NS" 2>/dev/null || true
info "If a LimitRange caps container memory below 32Gi, a 32Gi node-agent limit may be rejected or defaulted unexpectedly."

section "BACKUP STORAGE LOCATION"
if has_api 'backupstoragelocations.velero.io'; then
  BSL_JSON="$(oc get backupstoragelocations.velero.io -n "$OADP_NS" -o json 2>/dev/null || echo '{"items":[]}')"
  if [[ "$(jq '.items|length' <<<"$BSL_JSON")" -eq 0 ]]; then
    fail "No BackupStorageLocation found in $OADP_NS"
  else
    printf '%-36s %-14s %-25s %s\n' "NAME" "PHASE" "LAST-VALIDATED" "MESSAGE"
    jq -r '.items[] | [.metadata.name, (.status.phase // "<unset>"), (.status.lastValidationTime // "-"), (.status.message // "-")] | @tsv' <<<"$BSL_JSON" \
      | while IFS=$'\t' read -r name phase last msg; do
          printf '%-36s %-14s %-25s %s\n' "$name" "$phase" "$last" "$msg"
        done
    while IFS=$'\t' read -r name phase; do
      if [[ "$phase" == "Available" ]]; then
        pass "BSL $name is Available"
      else
        fail "BSL $name is not Available (phase=$phase)"
      fi
    done < <(jq -r '.items[] | [.metadata.name, (.status.phase // "<unset>")] | @tsv' <<<"$BSL_JSON")
  fi
else
  fail "BackupStorageLocation API not found"
fi

section "BACKUP REPOSITORY STATE"
_repo_found=0
for res in backuprepositories.velero.io resticrepositories.velero.io; do
  if has_api "$res"; then
    _repo_found=1
    info "$res"
    REPO_JSON="$(oc get "$res" -n "$OADP_NS" -o json 2>/dev/null || echo '{"items":[]}')"
    if [[ "$(jq '.items|length' <<<"$REPO_JSON")" -eq 0 ]]; then
      info "  none"
    else
      jq -r '.items[] | "  \(.metadata.name) phase=\(.status.phase // "<unset>") message=\(.status.message // "-")"' <<<"$REPO_JSON"
      while IFS=$'\t' read -r name phase; do
        case "$phase" in
          Ready|"") pass "$res/$name phase=${phase:-<empty>}" ;;
          *) warn "$res/$name phase=$phase; review repository health" ;;
        esac
      done < <(jq -r '.items[] | [.metadata.name, (.status.phase // "")] | @tsv' <<<"$REPO_JSON")
    fi
  fi
done
[[ "$_repo_found" -eq 0 ]] && info "No BackupRepository/ResticRepository API found (version/configuration dependent)"

section "ACTIVE / RECENT VELERO BACKUP & RESTORE OBJECTS"
for kind in backups.velero.io restores.velero.io; do
  if has_api "$kind"; then
    info "$kind"
    OBJ_JSON="$(oc get "$kind" -n "$OADP_NS" -o json 2>/dev/null || echo '{"items":[]}')"
    jq -r '.items[]? | [.metadata.name, (.status.phase // "<unset>"), (.metadata.creationTimestamp // "-")] | @tsv' <<<"$OBJ_JSON" \
      | sort -k3r | head -20 | column -t -s $'\t' 2>/dev/null || true

    while IFS=$'\t' read -r name phase; do
      case "$phase" in
        InProgress|WaitingForPluginOperations|WaitingForPluginOperationsPartiallyFailed|Finalizing|FinalizingPartiallyFailed|Deleting)
          warn "$kind/$name is still active or finalizing: $phase" ;;
        PartiallyFailed|Failed)
          warn "$kind/$name ended with $phase" ;;
      esac
    done < <(jq -r '.items[]? | [.metadata.name, (.status.phase // "<unset>")] | @tsv' <<<"$OBJ_JSON")
  fi
done

section "OADP POD HEALTH / OOM / RESTARTS"
OADP_PODS="$(oc get pods -n "$OADP_NS" -o json 2>/dev/null || echo '{"items":[]}')"
if [[ "$(jq '.items|length' <<<"$OADP_PODS")" -eq 0 ]]; then
  fail "No pods visible in OADP namespace $OADP_NS"
else
  oc get pods -n "$OADP_NS" -o wide 2>/dev/null || true

  while IFS=$'\t' read -r pod phase; do
    case "$phase" in Running|Succeeded) ;; *) warn "OADP pod $pod phase=$phase" ;; esac
  done < <(jq -r '.items[] | [.metadata.name, .status.phase] | @tsv' <<<"$OADP_PODS")

  while IFS=$'\t' read -r pod container restarts lastreason currentreason; do
    if (( restarts > 0 )); then
      warn "OADP pod $pod container=$container restartCount=$restarts lastReason=${lastreason:--}"
    fi
    if [[ "$lastreason" == "OOMKilled" || "$currentreason" == "OOMKilled" ]]; then
      fail "OOMKilled detected: $pod/$container"
    fi
  done < <(jq -r '.items[] as $p | (($p.status.containerStatuses // []) + ($p.status.initContainerStatuses // []))[]? | [$p.metadata.name, .name, (.restartCount // 0), (.lastState.terminated.reason // ""), (.state.terminated.reason // "")] | @tsv' <<<"$OADP_PODS")
fi

section "NODE-AGENT DAEMONSET"
DS_JSON="$(oc get daemonsets -n "$OADP_NS" -o json 2>/dev/null || echo '{"items":[]}')"
node_ds_count="$(jq '[.items[] | select(.metadata.name|test("node-agent|restic";"i"))] | length' <<<"$DS_JSON")"
if [[ "$node_ds_count" -eq 0 ]]; then
  info "No node-agent/restic DaemonSet found (may be expected depending on DPA/uploader configuration)"
else
  while IFS=$'\t' read -r name desired current ready available; do
    info "$name desired=$desired current=$current ready=$ready available=$available"
    if [[ "$desired" == "$ready" && "$desired" == "$available" ]]; then
      pass "$name is ready on all desired nodes"
    else
      fail "$name is not ready on all desired nodes"
    fi
  done < <(jq -r '.items[] | select(.metadata.name|test("node-agent|restic";"i")) | [.metadata.name, (.status.desiredNumberScheduled//0), (.status.currentNumberScheduled//0), (.status.numberReady//0), (.status.numberAvailable//0)] | @tsv' <<<"$DS_JSON")
fi

section "NODE MEMORY HEADROOM"
info "Node allocatable memory (for context; scheduler uses requests, not limits):"
oc get nodes -o json 2>/dev/null | jq -r '.items[] | [.metadata.name, (.status.allocatable.memory // "?")] | @tsv' | column -t 2>/dev/null || true

check_workloads_ns() {
  local ns="$1" label="$2"
  [[ -z "$ns" ]] && return
  if ! oc get ns "$ns" >/dev/null 2>&1; then return; fi

  section "$label CRONJOBS"
  CJ_JSON="$(oc get cronjobs.batch -n "$ns" -o json 2>/dev/null || echo '{"items":[]}')"
  if [[ "$(jq '.items|length' <<<"$CJ_JSON")" -eq 0 ]]; then
    info "No CronJobs in $ns"
  else
    printf '%-55s %-9s %-6s %-18s %-10s %-24s\n' "NAME" "SUSPEND" "ACTIVE" "SCHEDULE" "POLICY" "LAST"
    while IFS=$'\t' read -r name suspend active schedule policy last; do
      printf '%-55s %-9s %-6s %-18s %-10s %-24s\n' "$name" "$suspend" "$active" "$schedule" "$policy" "$last"
      if (( active > 0 )); then
        warn "CronJob $ns/$name currently has $active active Job(s)"
      fi
      if [[ "$suspend" != "true" ]]; then
        case "$name" in
          zen-rsi-evictor-cron-job)
            warn "Known review target present and NOT suspended: $ns/$name"
            ;;
          *backup*|*cleanup*|*purge*|*maintenance*|*evict*|*reconcile*|*sync*|*prune*)
            warn "Review unsuspended CronJob during backup window: $ns/$name"
            ;;
        esac
      fi
    done < <(jq -r '.items[] | [.metadata.name, (.spec.suspend // false), ((.status.active // [])|length), .spec.schedule, (.spec.concurrencyPolicy // "Allow"), (.status.lastScheduleTime // "-")] | @tsv' <<<"$CJ_JSON")
  fi

  section "$label UNFINISHED / FAILED JOBS"
  JOB_JSON="$(oc get jobs.batch -n "$ns" -o json 2>/dev/null || echo '{"items":[]}')"
  unfinished="$(jq '[.items[] | select(([.status.conditions[]? | select(((.type=="Complete") or (.type=="Failed")) and .status=="True")]|length)==0)] | length' <<<"$JOB_JSON")"
  if [[ "$unfinished" -eq 0 ]]; then
    pass "No unfinished Jobs in $ns"
  else
    warn "$unfinished unfinished Job(s) in $ns"
    jq -r '.items[] | select(([.status.conditions[]? | select(((.type=="Complete") or (.type=="Failed")) and .status=="True")]|length)==0) | [.metadata.name, ((.metadata.ownerReferences // [])|map(.kind+"/"+.name)|join(",")), (.status.active//0), (.status.succeeded//0), (.status.failed//0), (.status.startTime//"-")] | @tsv' <<<"$JOB_JSON" \
      | { column -t -s $'\t' 2>/dev/null || cat; }
  fi

  failed_jobs="$(jq '[.items[] | select([.status.conditions[]? | select(.type=="Failed" and .status=="True")]|length>0)] | length' <<<"$JOB_JSON")"
  if [[ "$failed_jobs" -gt 0 ]]; then
    warn "$failed_jobs Job(s) are in Failed condition in $ns (review recent failures)"
    jq -r '.items[] | select([.status.conditions[]? | select(.type=="Failed" and .status=="True")]|length>0) | [.metadata.name, (.status.failed//0), (.status.conditions[]? | select(.type=="Failed") | .reason//"-"), (.status.conditions[]? | select(.type=="Failed") | .message//"-")] | @tsv' <<<"$JOB_JSON" \
      | tail -20 | { column -t -s $'\t' 2>/dev/null || cat; }
  fi
}

check_workloads_ns "$CPD_NS" "CPD INSTANCE"
[[ -n "$CPD_OP_NS" && "$CPD_OP_NS" != "$CPD_NS" ]] && check_workloads_ns "$CPD_OP_NS" "CPD OPERATOR"

section "CPD POD HEALTH"
CPD_PODS="$(oc get pods -n "$CPD_NS" -o json 2>/dev/null || echo '{"items":[]}')"
terminating="$(jq '[.items[] | select(.metadata.deletionTimestamp != null)] | length' <<<"$CPD_PODS")"
if [[ "$terminating" -gt 0 ]]; then
  warn "$terminating terminating pod(s) exist before backup"
  jq -r '.items[] | select(.metadata.deletionTimestamp != null) | "  \(.metadata.name) deletingSince=\(.metadata.deletionTimestamp) phase=\(.status.phase)"' <<<"$CPD_PODS"
else
  pass "No terminating pods in $CPD_NS"
fi

while IFS=$'\t' read -r pod phase; do
  case "$phase" in Running|Succeeded) ;; *) warn "CPD pod $pod phase=$phase" ;; esac
done < <(jq -r '.items[] | [.metadata.name, .status.phase] | @tsv' <<<"$CPD_PODS")

while IFS=$'\t' read -r pod container reason; do
  case "$reason" in
    CrashLoopBackOff|ImagePullBackOff|ErrImagePull|CreateContainerConfigError|CreateContainerError|RunContainerError)
      warn "CPD pod $pod/$container waiting reason=$reason" ;;
  esac
done < <(jq -r '.items[] as $p | ($p.status.containerStatuses // [])[]? | [$p.metadata.name, .name, (.state.waiting.reason // "")] | @tsv' <<<"$CPD_PODS")

section "CPDBR-VOL-MNT CHECK"
VOLMNT="$(jq '[.items[] | select(.metadata.name|startswith("cpdbr-vol-mnt"))]' <<<"$CPD_PODS")"
if [[ "$(jq 'length' <<<"$VOLMNT")" -eq 0 ]]; then
  info "No cpdbr-vol-mnt pod exists now (normal when no offline backup is running)"
else
  jq -r '.[] | "\(.metadata.name) phase=\(.status.phase) node=\(.spec.nodeName // "-")"' <<<"$VOLMNT"
  while IFS=$'\t' read -r pod container restarts lastreason exitcode; do
    (( restarts > 0 )) && warn "$pod/$container restartCount=$restarts lastReason=${lastreason:--} exitCode=${exitcode:--}"
    if [[ "$lastreason" == "OOMKilled" || "$exitcode" == "137" ]]; then
      fail "cpdbr-vol-mnt OOM/exit137 detected: $pod/$container"
    fi
  done < <(jq -r '.[] as $p | (($p.status.containerStatuses // []) + ($p.status.initContainerStatuses // []))[]? | [$p.metadata.name, .name, (.restartCount//0), (.lastState.terminated.reason//""), ((.lastState.terminated.exitCode//"")|tostring)] | @tsv' <<<"$VOLMNT")
fi

section "PVC / STORAGE"
PVC_JSON="$(oc get pvc -n "$CPD_NS" -o json 2>/dev/null || echo '{"items":[]}')"
if [[ "$(jq '.items|length' <<<"$PVC_JSON")" -eq 0 ]]; then
  warn "No PVCs visible in $CPD_NS"
else
  printf '%-45s %-10s %-28s %-28s %s\n' "PVC" "PHASE" "STORAGECLASS" "PV" "REQUEST"
  while IFS=$'\t' read -r pvc phase sc pv req; do
    printf '%-45s %-10s %-28s %-28s %s\n' "$pvc" "$phase" "$sc" "$pv" "$req"
    [[ "$phase" != "Bound" ]] && warn "PVC $CPD_NS/$pvc is $phase (review whether expected)"
  done < <(jq -r '.items[] | [.metadata.name, (.status.phase//"?"), (.spec.storageClassName//"<none>"), (.spec.volumeName//"<none>"), (.spec.resources.requests.storage//"?")] | @tsv' <<<"$PVC_JSON")
fi

echo
info "StorageClasses:"
oc get sc -o custom-columns='NAME:.metadata.name,PROVISIONER:.provisioner,RECLAIM:.reclaimPolicy,BINDING:.volumeBindingMode,EXPAND:.allowVolumeExpansion' 2>/dev/null || true

echo
info "PV backend types used by CPD PVCs:"
while read -r pv; do
  [[ -z "$pv" || "$pv" == "null" || "$pv" == "<none>" ]] && continue
  oc get pv "$pv" -o json 2>/dev/null | jq -r '[.metadata.name, (.spec.storageClassName//"<none>"), (if .spec.nfs then "nfs" elif .spec.csi then ("csi:"+(.spec.csi.driver//"?")) else "other" end)] | @tsv'
done < <(jq -r '.items[].spec.volumeName // empty' <<<"$PVC_JSON") | column -t 2>/dev/null || true

section "LIKELY BACKUP/LOCK CONFIGMAPS (REVIEW ONLY)"
oc get cm -n "$CPD_NS" -o name 2>/dev/null | grep -Ei 'cpdbr|backup|checkpoint|ckpt|(^|[-])lock($|[-])|aux-.*-(br|ckpt)' | head -100 || info "No obvious matching ConfigMap names"
info "This section only lists candidates; the script cannot prove that every service-specific backup ConfigMap exists."

section "RECENT WARNING EVENTS"
for ns in "$CPD_NS" "$OADP_NS"; do
  info "Namespace: $ns"
  oc get events -n "$ns" --field-selector type=Warning --sort-by=.lastTimestamp 2>/dev/null | tail -30 || true
  echo
 done

if [[ "$SCAN_LOGS" -eq 1 ]]; then
  section "OPTIONAL LOG PATTERN SCAN"
  PATTERN='OOMKilled|exit code 137|exitCode.?137|repository is already locked|timed out waiting|NoCredentialProviders|SignatureDoesNotMatch|NoSuchKey|unable to open config|error pruning repository|PodVolumeBackup|PodVolumeRestore|BackupStorageLocation.*Unavailable|permission denied|operation not permitted'

  mapfile -t logpods < <(jq -r '.items[].metadata.name | select(test("velero|node-agent|restic";"i"))' <<<"$OADP_PODS")
  if [[ ${#logpods[@]} -eq 0 ]]; then
    info "No Velero/node-agent/restic pods found for log scan"
  else
    for pod in "${logpods[@]}"; do
      mapfile -t containers < <(oc get pod "$pod" -n "$OADP_NS" -o json 2>/dev/null | jq -r '.spec.containers[].name')
      for c in "${containers[@]}"; do
        hits="$(oc logs -n "$OADP_NS" "$pod" -c "$c" --tail="$LOG_TAIL" 2>/dev/null | grep -Ei "$PATTERN" | tail -20 || true)"
        if [[ -n "$hits" ]]; then
          warn "Suspicious patterns in $OADP_NS/$pod container=$c (last $LOG_TAIL lines)"
          printf '%s\n' "$hits" | sed 's/^/  /'
        fi
        # Previous container logs are especially useful after a restart/OOM.
        if oc get pod "$pod" -n "$OADP_NS" -o json 2>/dev/null | jq -e --arg c "$c" '.status.containerStatuses[]? | select(.name==$c and (.restartCount//0)>0)' >/dev/null; then
          prev="$(oc logs -n "$OADP_NS" "$pod" -c "$c" --previous --tail="$LOG_TAIL" 2>/dev/null | grep -Ei "$PATTERN" | tail -20 || true)"
          if [[ -n "$prev" ]]; then
            warn "Suspicious patterns in PREVIOUS logs: $OADP_NS/$pod container=$c"
            printf '%s\n' "$prev" | sed 's/^/  /'
          fi
        fi
      done
    done
  fi
fi

section "SUMMARY"
printf 'PASS=%d  WARN=%d  FAIL=%d\n' "$PASS" "$WARN" "$FAIL"

if (( FAIL > 0 )); then
  echo "RESULT: FAIL - resolve FAIL items before backup. WARN items also need review."
  exit 2
elif (( WARN > 0 )); then
  echo "RESULT: WARN - no hard failure detected by this script, but review WARN items before backup."
  exit 1
else
  echo "RESULT: PASS - no issue detected by these checks. This is not a guarantee of backup/restore success."
  exit 0
fi
