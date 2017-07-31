## Idle sessions termination

-- terminate idle session more than 3 minutes (>= 9.2)

SELECT pg_terminate_backend(pid)
FROM pg_stat_activity
WHERE datname = 'regress'
AND pid <> pg_backend_pid()
AND state = 'idle'
AND state_change < current_timestamp - INTERVAL '3' MINUTE;

-- if your db version is greater than or equal to 9.6
SET SESSION idle_in_transaction_session_timeout = '3min';

alter system set idle_in_transaction_session_timeout='3min';
