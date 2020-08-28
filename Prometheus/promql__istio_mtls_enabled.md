# How to verify whether mTLS is enabled or not through Prometheus.

```sql
sum(istio_requests_total{reporter="destination"}) by (connection_security_policy,destination_workload,source_workload)
```
