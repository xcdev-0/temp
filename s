oc get cronjob jobs-retention-check-cronjob -n ibm-cpd \
-o jsonpath='schedule={.spec.schedule}{"\n"}concurrencyPolicy={.spec.concurrencyPolicy}{"\n"}startingDeadlineSeconds={.spec.startingDeadlineSeconds}{"\n"}suspend={.spec.suspend}{"\n"}lastScheduleTime={.status.lastScheduleTime}{"\n"}'
