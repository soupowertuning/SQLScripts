
WITH [Waits] AS (SELECT
[wait_type],
[wait_time_ms] / 1000.0 AS [WaitS],
([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
[signal_wait_time_ms] / 1000.0 AS [SignalS],
[waiting_tasks_count] AS [WaitCount],
100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
FROM sys.dm_os_wait_stats
 
WHERE [wait_type] NOT IN (
N'BROKER_EVENTHANDLER', N'BROKER_RECEIVE_WAITFOR',
N'BROKER_TASK_STOP', N'BROKER_TO_FLUSH',
N'BROKER_TRANSMITTER', N'CHECKPOINT_QUEUE',
N'CHKPT', N'CLR_AUTO_EVENT',
N'CLR_MANUAL_EVENT', N'CLR_SEMAPHORE',
N'DBMIRROR_DBM_EVENT', N'DBMIRROR_EVENTS_QUEUE',
N'DBMIRROR_WORKER_QUEUE', N'DBMIRRORING_CMD',
N'DIRTY_PAGE_POLL', N'DISPATCHER_QUEUE_SEMAPHORE',
N'EXECSYNC', N'FSAGENT',
N'FT_IFTS_SCHEDULER_IDLE_WAIT', N'FT_IFTSHC_MUTEX',
N'HADR_CLUSAPI_CALL', N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
N'HADR_LOGCAPTURE_WAIT', N'HADR_NOTIFICATION_DEQUEUE',
N'HADR_TIMER_TASK', N'HADR_WORK_QUEUE',
N'KSOURCE_WAKEUP', N'LAZYWRITER_SLEEP',
N'LOGMGR_QUEUE', N'ONDEMAND_TASK_QUEUE',
N'PWAIT_ALL_COMPONENTS_INITIALIZED',
N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
N'REQUEST_FOR_DEADLOCK_SEARCH', N'RESOURCE_QUEUE',
N'SERVER_IDLE_CHECK', N'SLEEP_BPOOL_FLUSH',
N'SLEEP_DBSTARTUP', N'SLEEP_DCOMSTARTUP',
N'SLEEP_MASTERDBREADY', N'SLEEP_MASTERMDREADY',
N'SLEEP_MASTERUPGRADED', N'SLEEP_MSDBSTARTUP',
N'SLEEP_SYSTEMTASK', N'SLEEP_TASK',
N'SLEEP_TEMPDBSTARTUP', N'SNI_HTTP_ACCEPT',
N'SP_SERVER_DIAGNOSTICS_SLEEP', N'SQLTRACE_BUFFER_FLUSH',
N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
N'SQLTRACE_WAIT_ENTRIES', N'WAIT_FOR_RESULTS',
N'WAITFOR', N'WAITFOR_TASKSHUTDOWN',
N'WAIT_XTP_HOST_WAIT', N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
N'WAIT_XTP_CKPT_CLOSE', N'XE_DISPATCHER_JOIN',
N'XE_DISPATCHER_WAIT', N'XE_TIMER_EVENT')
)
SELECT
 
[W1].[wait_type] AS [WaitType],
Wait_Type_Description =
case
 
when [W1].[wait_type] = 'ABR' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'ASSEMBLY_LOAD' then 'Occurs during exclusive access to assembly loading.'
 
when [W1].[wait_type] = 'ASYNC_DISKPOOL_LOCK' then 'Occurs when there is an attempt to synchronize parallel threads that are performing tasks such as creating or initializing a file.'
 
when [W1].[wait_type] = 'ASYNC_IO_COMPLETION' then 'Occurs when a task is waiting for I/Os to finish.'
 
when [W1].[wait_type] = 'ASYNC_NETWORK_IO' then 'Occurs on network writes when the task is blocked behind the network. Verify that the client is processing data from the server.'
 
when [W1].[wait_type] = 'AUDIT_GROUPCACHE_LOCK' then 'Occurs when there is a wait on a lock that controls access to a special cache. The cache contains information about which audits are being used to audit each audit action group.'
 
when [W1].[wait_type] = 'AUDIT_LOGINCACHE_LOCK' then 'Occurs when there is a wait on a lock that controls access to a special cache. The cache contains information about which audits are being used to audit login audit action groups.'
 
when [W1].[wait_type] = 'AUDIT_ON_DEMAND_TARGET_LOCK' then 'Occurs when there is a wait on a lock that is used to ensure single initialization of audit related Extended Event targets.'
 
when [W1].[wait_type] = 'AUDIT_XE_SESSION_MGR' then 'Occurs when there is a wait on a lock that is used to synchronize the starting and stopping of audit related Extended Events sessions.'
 
when [W1].[wait_type] = 'BACKUP' then 'Occurs when a task is blocked as part of backup processing.'
 
when [W1].[wait_type] = 'BACKUP_OPERATOR' then 'Occurs when a task is waiting for a tape mount. To view the tape status, query sys.dm_io_backup_tapes. If a mount operation is not pending, this wait type may indicate a hardware problem with the tape drive.'
 
when [W1].[wait_type] = 'BACKUPBUFFER' then 'Occurs when a backup task is waiting for data, or is waiting for a buffer in which to store data. This type is not typical, except when a task is waiting for a tape mount.'
 
when [W1].[wait_type] = 'BACKUPIO' then 'Occurs when a backup task is waiting for data, or is waiting for a buffer in which to store data. This type is not typical, except when a task is waiting for a tape mount.'
 
when [W1].[wait_type] = 'BACKUPTHREAD' then 'Occurs when a task is waiting for a backup task to finish. Wait times may be long, from several minutes to several hours. If the task that is being waited on is in an I/O process, this type does not indicate a problem.'
 
when [W1].[wait_type] = 'BAD_PAGE_PROCESS' then 'Occurs when the background suspect page logger is trying to avoid running more than every five seconds. Excessive suspect pages cause the logger to run frequently.'
 
when [W1].[wait_type] = 'BROKER_CONNECTION_RECEIVE_TASK' then 'Occurs when waiting for access to receive a message on a connection endpoint. Receive access to the endpoint is serialized.'
 
when [W1].[wait_type] = 'BROKER_ENDPOINT_STATE_MUTEX' then 'Occurs when there is contention to access the state of a Service Broker connection endpoint. Access to the state for changes is serialized.'
 
when [W1].[wait_type] = 'BROKER_EVENTHANDLER' then 'Occurs when a task is waiting in the primary event handler of the Service Broker. This should occur very briefly.'
 
when [W1].[wait_type] = 'BROKER_INIT' then 'Occurs when initializing Service Broker in each active database. This should occur infrequently.'
 
when [W1].[wait_type] = 'BROKER_MASTERSTART' then 'Occurs when a task is waiting for the primary event handler of the Service Broker to start. This should occur very briefly.'
 
when [W1].[wait_type] = 'BROKER_RECEIVE_WAITFOR' then 'Occurs when the RECEIVE WAITFOR is waiting. This is typical if no messages are ready to be received.'
 
when [W1].[wait_type] = 'BROKER_REGISTERALLENDPOINTS' then 'Occurs during the initialization of a Service Broker connection endpoint. This should occur very briefly.'
 
when [W1].[wait_type] = 'BROKER_SERVICE' then 'Occurs when the Service Broker destination list that is associated with a target service is updated or re-prioritized.'
 
when [W1].[wait_type] = 'BROKER_SHUTDOWN' then 'Occurs when there is a planned shutdown of Service Broker. This should occur very briefly, if at all.'
 
when [W1].[wait_type] = 'BROKER_TASK_STOP' then 'Occurs when the Service Broker queue task handler tries to shut down the task. The state check is serialized and must be in a running state beforehand.'
 
when [W1].[wait_type] = 'BROKER_TO_FLUSH' then 'Occurs when the Service Broker lazy flusher flushes the in-memory transmission objects to a work table.'
 
when [W1].[wait_type] = 'BROKER_TRANSMITTER' then 'Occurs when the Service Broker transmitter is waiting for work.'
 
when [W1].[wait_type] = 'BUILTIN_HASHKEY_MUTEX' then 'May occur after startup of instance, while internal data structures are initializing. Will not recur once data structures have initialized.'
 
when [W1].[wait_type] = 'CHECK_PRINT_RECORD' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'CHECKPOINT_QUEUE' then 'Occurs while the checkpoint task is waiting for the next checkpoint request.'
 
when [W1].[wait_type] = 'CHKPT' then 'Occurs at server startup to tell the checkpoint thread that it can start.'
 
when [W1].[wait_type] = 'CLEAR_DB' then 'Occurs during operations that change the state of a database, such as opening or closing a database.'
 
when [W1].[wait_type] = 'CLR_AUTO_EVENT' then 'Occurs when a task is currently performing common language runtime (CLR) execution and is waiting for a particular autoevent to be initiated. Long waits are typical, and do not indicate a problem.'
 
when [W1].[wait_type] = 'CLR_CRST' then 'Occurs when a task is currently performing CLR execution and is waiting to enter a critical section of the task that is currently being used by another task.'
 
when [W1].[wait_type] = 'CLR_JOIN' then 'Occurs when a task is currently performing CLR execution and waiting for another task to end. This wait state occurs when there is a join between tasks.'
 
when [W1].[wait_type] = 'CLR_MANUAL_EVENT' then 'Occurs when a task is currently performing CLR execution and is waiting for a specific manual event to be initiated.'
 
when [W1].[wait_type] = 'CLR_MEMORY_SPY' then 'Occurs during a wait on lock acquisition for a data structure that is used to record all virtual memory allocations that come from CLR. The data structure is locked to maintain its integrity if there is parallel access.'
 
when [W1].[wait_type] = 'CLR_MONITOR' then 'Occurs when a task is currently performing CLR execution and is waiting to obtain a lock on the monitor.'
 
when [W1].[wait_type] = 'CLR_RWLOCK_READER' then 'Occurs when a task is currently performing CLR execution and is waiting for a reader lock.'
 
when [W1].[wait_type] = 'CLR_RWLOCK_WRITER' then 'Occurs when a task is currently performing CLR execution and is waiting for a writer lock.'
 
when [W1].[wait_type] = 'CLR_SEMAPHORE' then 'Occurs when a task is currently performing CLR execution and is waiting for a semaphore.'
 
when [W1].[wait_type] = 'CLR_TASK_START' then 'Occurs while waiting for a CLR task to complete startup.'
 
when [W1].[wait_type] = 'CLRHOST_STATE_ACCESS' then 'Occurs where there is a wait to acquire exclusive access to the CLR-hosting data structures. This wait type occurs while setting up or tearing down the CLR runtime.'
 
when [W1].[wait_type] = 'CMEMTHREAD' then 'Occurs when a task is waiting on a thread-safe memory object. The wait time might increase when there is contention caused by multiple tasks trying to allocate memory from the same memory object.'
 
when [W1].[wait_type] = 'CXPACKET' then 'Occurs when trying to synchronize the query processor exchange iterator. You may consider lowering the degree of parallelism if contention on this wait type becomes a problem.'
 
when [W1].[wait_type] = 'CXROWSET_SYNC' then 'Occurs during a parallel range scan.'
 
when [W1].[wait_type] = 'DAC_INIT' then 'Occurs while the dedicated administrator connection is initializing.'
 
when [W1].[wait_type] = 'DBMIRROR_DBM_EVENT' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'DBMIRROR_DBM_MUTEX' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'DBMIRROR_EVENTS_QUEUE' then 'Occurs when database mirroring waits for events to process.'
 
when [W1].[wait_type] = 'DBMIRROR_SEND' then 'Occurs when a task is waiting for a communications backlog at the network layer to clear to be able to send messages. Indicates that the communications layer is starting to become overloaded and affect the database mirroring data throughput.'
 
when [W1].[wait_type] = 'DBMIRROR_WORKER_QUEUE' then 'Indicates that the database mirroring worker task is waiting for more work.'
 
when [W1].[wait_type] = 'DBMIRRORING_CMD' then 'Occurs when a task is waiting for log records to be flushed to disk. This wait state is expected to be held for long periods of time.'
 
when [W1].[wait_type] = 'DEADLOCK_ENUM_MUTEX' then 'Occurs when the deadlock monitor and sys.dm_os_waiting_tasks try to make sure that SQL Server is not running multiple deadlock searches at the same time.'
 
when [W1].[wait_type] = 'DEADLOCK_TASK_SEARCH' then 'Large waiting time on this resource indicates that the server is executing queries on top of sys.dm_os_waiting_tasks, and these queries are blocking deadlock monitor from running deadlock search. This wait type is used by deadlock monitor only. Queries on'
 
when [W1].[wait_type] = 'DEBUG' then 'Occurs during Transact-SQL and CLR debugging for internal synchronization.'
 
when [W1].[wait_type] = 'DISABLE_VERSIONING' then 'Occurs when SQL Server polls the version transaction manager to see whether the timestamp of the earliest active transaction is later than the timestamp of when the state started changing. If this is this case, all the snapshot transactions that were star'
 
when [W1].[wait_type] = 'DISKIO_SUSPEND' then 'Occurs when a task is waiting to access a file when an external backup is active. This is reported for each waiting user process. A count larger than five per user process may indicate that the external backup is taking too much time to finish.'
 
when [W1].[wait_type] = 'DISPATCHER_QUEUE_SEMAPHORE' then 'Occurs when a thread from the dispatcher pool is waiting for more work to process. The wait time for this wait type is expected to increase when the dispatcher is idle.'
 
when [W1].[wait_type] = 'DLL_LOADING_MUTEX' then 'Occurs once while waiting for the XML parser DLL to load.'
 
when [W1].[wait_type] = 'DROPTEMP' then 'Occurs between attempts to drop a temporary object if the previous attempt failed. The wait duration grows exponentially with each failed drop attempt.'
 
when [W1].[wait_type] = 'DTC' then 'Occurs when a task is waiting on an event that is used to manage state transition. This state controls when the recovery of Microsoft Distributed Transaction Coordinator (MS DTC) transactions occurs after SQL Server receives notification that the MS DTC s'
 
when [W1].[wait_type] = 'DTC_ABORT_REQUEST' then 'Occurs in a MS DTC worker session when the session is waiting to take ownership of a MS DTC transaction. After MS DTC owns the transaction, the session can roll back the transaction. Generally, the session will wait for another session that is using the t'
 
when [W1].[wait_type] = 'DTC_RESOLVE' then 'Occurs when a recovery task is waiting for the master database in a cross-database transaction so that the task can query the outcome of the transaction.'
 
when [W1].[wait_type] = 'DTC_STATE' then 'Occurs when a task is waiting on an event that protects changes to the internal MS DTC global state object. This state should be held for very short periods of time.'
 
when [W1].[wait_type] = 'DTC_TMDOWN_REQUEST' then 'Occurs in a MS DTC worker session when SQL Server receives notification that the MS DTC service is not available. First, the worker will wait for the MS DTC recovery process to start. Then, the worker waits to obtain the outcome of the distributed transac'
 
when [W1].[wait_type] = 'DTC_WAITFOR_OUTCOME' then 'Occurs when recovery tasks wait for MS DTC to become active to enable the resolution of prepared transactions.'
 
when [W1].[wait_type] = 'DUMP_LOG_COORDINATOR' then 'Occurs when a main task is waiting for a subtask to generate data. Ordinarily, this state does not occur. A long wait indicates an unexpected blockage. The subtask should be investigated.'
 
when [W1].[wait_type] = 'DUMPTRIGGER' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'EC' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'EE_PMOLOCK' then 'Occurs during synchronization of certain types of memory allocations during statement execution.'
 
when [W1].[wait_type] = 'EE_SPECPROC_MAP_INIT' then 'Occurs during synchronization of internal procedure hash table creation. This wait can only occur during the initial accessing of the hash table after the SQL Server instance starts.'
 
when [W1].[wait_type] = 'ENABLE_VERSIONING' then 'Occurs when SQL Server waits for all update transactions in this database to finish before declaring the database ready to transition to snapshot isolation allowed state. This state is used when SQL Server enables snapshot isolation by using the ALTER DAT'
 
when [W1].[wait_type] = 'ERROR_REPORTING_MANAGER' then 'Occurs during synchronization of multiple concurrent error log initializations.'
 
when [W1].[wait_type] = 'EXCHANGE' then 'Occurs during synchronization in the query processor exchange iterator during parallel queries.'
 
when [W1].[wait_type] = 'EXECSYNC' then 'Occurs during parallel queries while synchronizing in query processor in areas not related to the exchange iterator. Examples of such areas are bitmaps, large binary objects (LOBs), and the spool iterator. LOBs may frequently use this wait state.'
 
when [W1].[wait_type] = 'EXECUTION_PIPE_EVENT_INTERNAL' then 'Occurs during synchronization between producer and consumer parts of batch execution that are submitted through the connection context.'
 
when [W1].[wait_type] = 'FAILPOINT' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'FCB_REPLICA_READ' then 'Occurs when the reads of a snapshot (or a temporary snapshot created by DBCC) sparse file are synchronized.'
 
when [W1].[wait_type] = 'FCB_REPLICA_WRITE' then 'Occurs when the pushing or pulling of a page to a snapshot (or a temporary snapshot created by DBCC) sparse file is synchronized.'
 
when [W1].[wait_type] = 'FS_FC_RWLOCK' then 'Occurs when there is a wait by the FILESTREAM garbage collector to do either of the following: Disable garbage collection (used by backup and restore). '
 
when [W1].[wait_type] = 'FS_GARBAGE_COLLECTOR_SHUTDOWN' then 'Occurs when the FILESTREAM garbage collector is waiting for cleanup tasks to be completed.'
 
when [W1].[wait_type] = 'FS_HEADER_RWLOCK' then 'Occurs when there is a wait to acquire access to the FILESTREAM header of a FILESTREAM data container to either read or update contents in the FILESTREAM header file (Filestream.hdr).'
 
when [W1].[wait_type] = 'FS_LOGTRUNC_RWLOCK' then 'Occurs when there is a wait to acquire access to FILESTREAM log truncation to do either of the following: Temporarily disable FILESTREAM log (FSLOG) truncation (used by b'
 
when [W1].[wait_type] = 'FSA_FORCE_OWN_XACT' then 'Occurs when a FILESTREAM file I/O operation needs to bind to the associated transaction, but the transaction is currently owned by another session.'
 
when [W1].[wait_type] = 'FSAGENT' then 'Occurs when a FILESTREAM file I/O operation is waiting for a FILESTREAM agent resource that is being used by another file I/O operation.'
 
when [W1].[wait_type] = 'FSTR_CONFIG_MUTEX' then 'Occurs when there is a wait for another FILESTREAM feature reconfiguration to be completed.'
 
when [W1].[wait_type] = 'FSTR_CONFIG_RWLOCK' then 'Occurs when there is a wait to serialize access to the FILESTREAM configuration parameters.'
 
when [W1].[wait_type] = 'FT_METADATA_MUTEX' then 'Documented for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'FT_RESTART_CRAWL' then 'Occurs when a full-text crawl needs to restart from a last known good point to recover from a transient failure. The wait lets the worker tasks currently working on that population to complete or exit the current step.'
 
when [W1].[wait_type] = 'FULLTEXT GATHERER' then 'Occurs during synchronization of full-text operations.'
 
when [W1].[wait_type] = 'GUARDIAN' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'HADR_AG_MUTEX' then 'Occurs when an AlwaysOn DDL statement or Windows Server Failover Clustering command is waiting for exclusive read/write access to the configuration of an availability group.'
 
when [W1].[wait_type] = 'HADR_AR_CRITICAL_SECTION_ENTRY' then 'Occurs when an AlwaysOn DDL statement or Windows Server Failover Clustering command is waiting for exclusive read/write access to the runtime state of the local replica of the associated availability group.'
 
when [W1].[wait_type] = 'HADR_AR_MANAGER_MUTEX' then 'Occurs when an availability replica shutdown is waiting for startup to complete or an availability replica startup is waiting for shutdown to complete. Internal use only. Note Availability replica shutdown is initiated either by SQL Server shutdo'
 
when [W1].[wait_type] = 'HADR_ARCONTROLLER_NOTIFICATIONS_SUBSCRIBER_LIST' then 'The publisher for an availability replica event (such as a state change or configuration change) is waiting for exclusive read/write access to the list of event subscribers. Internal use only.'
 
when [W1].[wait_type] = 'HADR_BACKUP_BULK_LOCK' then 'The AlwaysOn primary database received a backup request from a secondary database and is waiting for the background thread to finish processing the request on acquiring or releasing the BulkOp lock.'
 
when [W1].[wait_type] = 'HADR_BACKUP_QUEUE' then 'The backup background thread of the AlwaysOn primary database is waiting for a new work request from the secondary database. (typically, this occurs when the primary database is holding the BulkOp log and is waiting for the secondary database to indicate '
 
when [W1].[wait_type] = 'HADR_CLUSAPI_CALL' then 'A SQL Server thread is waiting to switch from non-preemptive mode (scheduled by SQL Server) to preemptive mode (scheduled by the operating system) in order to invoke Windows Server Failover Clustering APIs.'
 
when [W1].[wait_type] = 'HADR_COMPRESSED_CACHE_SYNC' then 'Waiting for access to the cache of compressed log blocks that is used to avoid redundant compression of the log blocks sent to multiple secondary databases.'
 
when [W1].[wait_type] = 'HADR_DATABASE_FLOW_CONTROL' then 'Waiting for messages to be sent to the partner when the maximum number of queued messages has been reached. Indicates that the log scans are running faster than the network sends. This is an issue only if network sends are slower than expected.'
 
when [W1].[wait_type] = 'HADR_DATABASE_VERSIONING_STATE' then 'Occurs on the versioning state change of an AlwaysOn secondary database. This wait is for internal data structures and is usually is very short with no direct effect on data access.'
 
when [W1].[wait_type] = 'HADR_DATABASE_WAIT_FOR_RESTART' then 'Waiting for the database to restart under AlwaysOn Availability Groups control. Under normal conditions, this is not a customer issue because waits are expected here.'
 
when [W1].[wait_type] = 'HADR_DATABASE_WAIT_FOR_TRANSITION_TO_VERSIONING' then 'A query on object(s) in a readable secondary database of an AlwaysOn availability group is blocked on row versioning while waiting for commit or rollback of all transactions that were in-flight when the secondary replica was enabled for read workloads. Th'
 
when [W1].[wait_type] = 'HADR_DB_COMMAND' then 'Waiting for responses to conversational messages (which require an explicit response from the other side, using the AlwaysOn conversational message infrastructure). A number of different message types use this wait type.'
 
when [W1].[wait_type] = 'HADR_DB_OP_COMPLETION_SYNC' then 'Waiting for responses to conversational messages (which require an explicit response from the other side, using the AlwaysOn conversational message infrastructure). A number of different message types use this wait type.'
 
when [W1].[wait_type] = 'HADR_DB_OP_START_SYNC' then 'An AlwaysOn DDL statement or a Windows Server Failover Clustering command is waiting for serialized access to an availability database and its runtime state.'
 
when [W1].[wait_type] = 'HADR_DBR_SUBSCRIBER' then 'The publisher for an availability replica event (such as a state change or configuration change) is waiting for exclusive read/write access to the runtime state of an event subscriber that corresponds to an availability database. Internal use only.'
 
when [W1].[wait_type] = 'HADR_DBR_SUBSCRIBER_FILTER_LIST' then 'The publisher for an availability replica event (such as a state change or configuration change) is waiting for exclusive read/write access to the list of event subscribers that correspond to availability databases. Internal use only.'
 
when [W1].[wait_type] = 'HADR_DBSTATECHANGE_SYNC' then 'Concurrency control wait for updating the internal state of the database replica.'
 
when [W1].[wait_type] = 'HADR_FILESTREAM_BLOCK_FLUSH' then 'The FILESTREAM AlwaysOn transport manager is waiting until processing of a log block is finished.'
 
when [W1].[wait_type] = 'HADR_FILESTREAM_FILE_CLOSE' then 'The FILESTREAM AlwaysOn transport manager is waiting until the next FILESTREAM file gets processed and its handle gets closed.'
 
when [W1].[wait_type] = 'HADR_FILESTREAM_FILE_REQUEST' then 'An AlwaysOn secondary replica is waiting for the primary replica to send all requested FILESTREAM files during UNDO.'
 
when [W1].[wait_type] = 'HADR_FILESTREAM_IOMGR' then 'The FILESTREAM AlwaysOn transport manager is waiting for R/W lock that protects the FILESTREAM AlwaysOn I/O manager during startup or shutdown.'
 
when [W1].[wait_type] = 'HADR_FILESTREAM_IOMGR_IOCOMPLETION' then 'The FILESTREAM AlwaysOn I/O manager is waiting for I/O completion.'
 
when [W1].[wait_type] = 'HADR_FILESTREAM_MANAGER' then 'The FILESTREAM AlwaysOn transport manager is waiting for the R/W lock that protects the FILESTREAM AlwaysOn transport manager during startup or shutdown.'
 
when [W1].[wait_type] = 'HADR_GROUP_COMMIT' then 'Transaction commit processing is waiting to allow a group commit so that multiple commit log records can be put into a single log block. This wait is an expected condition that optimizes the log I/O, capture, and send operations.'
 
when [W1].[wait_type] = 'HADR_LOGCAPTURE_SYNC' then 'Concurrency control around the log capture or apply object when creating or destroying scans. This is an expected wait when partners change state or connection status.'
 
when [W1].[wait_type] = 'HADR_LOGCAPTURE_WAIT' then 'Waiting for log records to become available. Can occur either when waiting for new log records to be generated by connections or for I/O completion when reading log not in the cache. This is an expected wait if the log scan is caught up to the end of log '
 
when [W1].[wait_type] = 'HADR_LOGPROGRESS_SYNC' then 'Concurrency control wait when updating the log progress status of database replicas.'
 
when [W1].[wait_type] = 'HADR_NOTIFICATION_DEQUEUE' then 'A background task that processes Windows Server Failover Clustering notifications is waiting for the next notification. Internal use only.'
 
when [W1].[wait_type] = 'HADR_NOTIFICATION_WORKER_EXCLUSIVE_ACCESS' then 'The AlwaysOn availability replica manager is waiting for serialized access to the runtime state of a background task that processes Windows Server Failover Clustering notifications. Internal use only.'
 
when [W1].[wait_type] = 'HADR_NOTIFICATION_WORKER_STARTUP_SYNC' then 'A background task is waiting for the completion of the startup of a background task that processes Windows Server Failover Clustering notifications. Internal use only.'
 
when [W1].[wait_type] = 'HADR_NOTIFICATION_WORKER_TERMINATION_SYNC' then 'A background task is waiting for the termination of a background task that processes Windows Server Failover Clustering notifications. Internal use only.'
 
when [W1].[wait_type] = 'HADR_PARTNER_SYNC' then 'Concurrency control wait on the partner list.'
 
when [W1].[wait_type] = 'HADR_READ_ALL_NETWORKS' then 'Waiting to get read or write access to the list of WSFC networks. Internal use only. -Note '
 
when [W1].[wait_type] = 'HADR_RECOVERY_WAIT_FOR_CONNECTION' then 'Waiting for the secondary database to connect to the primary database before running recovery. This is an expected wait, which can lengthen if the connection to the primary is slow to establish.'
 
when [W1].[wait_type] = 'HADR_RECOVERY_WAIT_FOR_UNDO' then 'Database recovery is waiting for the secondary database to finish the reverting and initializing phase to bring it back to the common log point with the primary database. This is an expected wait after failovers.Undo progress can be tracked through the Wi'
 
when [W1].[wait_type] = 'HADR_REPLICAINFO_SYNC' then 'Waiting for concurrency control to update the current replica state.'
 
when [W1].[wait_type] = 'HADR_SYNC_COMMIT' then 'Waiting for transaction commit processing for the synchronized secondary databases to harden the log. This wait is also reflected by the Transaction Delay performance counter. This wait type is expected for synchronized availability groups and indicates t'
 
when [W1].[wait_type] = 'HADR_SYNCHRONIZING_THROTTLE' then 'Waiting for transaction commit processing to allow a synchronizing secondary database to catch up to the primary end of log in order to transition to the synchronized state. This is an expected wait when a secondary database is catching up.'
 
when [W1].[wait_type] = 'HADR_TDS_LISTENER_SYNC' then 'Either the internal AlwaysOn system or the WSFC cluster will request that listeners are started or stopped. The processing of this request is always asynchronous, and there is a mechanism to remove redundant requests. There are also moments that this proc'
 
when [W1].[wait_type] = 'HADR_TDS_LISTENER_SYNC_PROCESSING' then 'Used at the end of an AlwaysOn Transact-SQL statement that requires starting and/or stopping anavailability group listener. Since the start/stop operation is done asynchronously, the user thread will block using this wait type until the situation of the l'
 
when [W1].[wait_type] = 'HADR_TIMER_TASK' then 'Waiting to get the lock on the timer task object and is also used for the actual waits between times that work is being performed. For example, for a task that runs every 10 seconds, after one execution, AlwaysOn Availability Groups waits about 10 seconds'
 
when [W1].[wait_type] = 'HADR_TRANSPORT_DBRLIST' then 'Waiting for access to the transport layers database replica list. Used for the spinlock that grants access to it.'
 
when [W1].[wait_type] = 'HADR_TRANSPORT_FLOW_CONTROL' then 'Waiting when the number of outstanding unacknowledged AlwaysOn messages is over the out flow control threshold. This is on an availability replica-to-replica basis (not on a database-to-database basis).'
 
when [W1].[wait_type] = 'HADR_TRANSPORT_SESSION' then 'AlwaysOn Availability Groups is waiting while changing or accessing the underlying transport state.'
 
when [W1].[wait_type] = 'HADR_WORK_POOL' then 'Concurrency control wait on the AlwaysOn Availability Groups background work task object.'
 
when [W1].[wait_type] = 'HADR_WORK_QUEUE' then 'AlwaysOn Availability Groups background worker thread waiting for new work to be assigned. This is an expected wait when there are ready workers waiting for new work, which is the normal state.'
 
when [W1].[wait_type] = 'HADR_XRF_STACK_ACCESS' then 'Accessing (look up, add, and delete) the extended recovery fork stack for an AlwaysOn availability database.'
 
when [W1].[wait_type] = 'HTTP_ENUMERATION' then 'Occurs at startup to enumerate the HTTP endpoints to start HTTP.'
 
when [W1].[wait_type] = 'HTTP_START' then 'Occurs when a connection is waiting for HTTP to complete initialization.'
 
when [W1].[wait_type] = 'IMPPROV_IOWAIT' then 'Occurs when SQL Server waits for a bulkload I/O to finish.'
 
when [W1].[wait_type] = 'INTERNAL_TESTING' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'IO_AUDIT_MUTEX' then 'Occurs during synchronization of trace event buffers.'
 
when [W1].[wait_type] = 'IO_COMPLETION' then 'Occurs while waiting for I/O operations to complete. This wait type generally represents non-data page I/Os. Data page I/O completion waits appear as PAGEIOLATCH_* waits.'
 
when [W1].[wait_type] = 'IO_RETRY' then 'Occurs when an I/O operation such as a read or a write to disk fails because of insufficient resources, and is then retried.'
 
when [W1].[wait_type] = 'IOAFF_RANGE_QUEUE' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'KSOURCE_WAKEUP' then 'Used by the service control task while waiting for requests from the Service Control Manager. Long waits are expected and do not indicate a problem.'
 
when [W1].[wait_type] = 'KTM_ENLISTMENT' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'KTM_RECOVERY_MANAGER' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'KTM_RECOVERY_RESOLUTION' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'LATCH_DT' then 'Occurs when waiting for a DT (destroy) latch. This does not include buffer latches or transaction mark latches. A listing of LATCH_* waits is available in sys.dm_os_latch_stats. Note that sys.dm_os_latch_stats groups LATCH_NL, LATCH_SH, LATCH_UP, LATCH_EX'
 
when [W1].[wait_type] = 'LATCH_EX' then 'Occurs when waiting for an EX (exclusive) latch. This does not include buffer latches or transaction mark latches. A listing of LATCH_* waits is available in sys.dm_os_latch_stats. Note that sys.dm_os_latch_stats groups LATCH_NL, LATCH_SH, LATCH_UP, LATCH'
 
when [W1].[wait_type] = 'LATCH_KP' then 'Occurs when waiting for a KP (keep) latch. This does not include buffer latches or transaction mark latches. A listing of LATCH_* waits is available in sys.dm_os_latch_stats. Note that sys.dm_os_latch_stats groups LATCH_NL, LATCH_SH, LATCH_UP, LATCH_EX, a'
 
when [W1].[wait_type] = 'LATCH_NL' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'LATCH_SH' then 'Occurs when waiting for an SH (share) latch. This does not include buffer latches or transaction mark latches. A listing of LATCH_* waits is available in sys.dm_os_latch_stats. Note that sys.dm_os_latch_stats groups LATCH_NL, LATCH_SH, LATCH_UP, LATCH_EX,'
 
when [W1].[wait_type] = 'LATCH_UP' then 'Occurs when waiting for an UP (update) latch. This does not include buffer latches or transaction mark latches. A listing of LATCH_* waits is available in sys.dm_os_latch_stats. Note that sys.dm_os_latch_stats groups LATCH_NL, LATCH_SH, LATCH_UP, LATCH_EX'
 
when [W1].[wait_type] = 'LAZYWRITER_SLEEP' then 'Occurs when lazywriter tasks are suspended. This is a measure of the time spent by background tasks that are waiting. Do not consider this state when you are looking for user stalls.'
 
when [W1].[wait_type] = 'LCK_M_BU' then 'Occurs when a task is waiting to acquire a Bulk Update (BU) lock. For a lock compatibility matrix, seesys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_IS' then 'Occurs when a task is waiting to acquire an Intent Shared (IS) lock. For a lock compatibility matrix, seesys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_IU' then 'Occurs when a task is waiting to acquire an Intent Update (IU) lock. For a lock compatibility matrix, seesys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_IX' then 'Occurs when a task is waiting to acquire an Intent Exclusive (IX) lock. For a lock compatibility matrix, seesys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_RIn_NL' then 'Occurs when a task is waiting to acquire a NULL lock on the current key value, and an Insert Range lock between the current and previous key. A NULL lock on the key is an instant release lock. For a lock compatibility matrix, see sys.dm_tran_locks (Transa'
 
when [W1].[wait_type] = 'LCK_M_RIn_S' then 'Occurs when a task is waiting to acquire a shared lock on the current key value, and an Insert Range lock between the current and previous key. For a lock compatibility matrix, see sys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_RIn_U' then 'Task is waiting to acquire an Update lock on the current key value, and an Insert Range lock between the current and previous key. For a lock compatibility matrix, see sys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_RIn_X' then 'Occurs when a task is waiting to acquire an Exclusive lock on the current key value, and an Insert Range lock between the current and previous key. For a lock compatibility matrix, see sys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_RS_S' then 'Occurs when a task is waiting to acquire a Shared lock on the current key value, and a Shared Range lock between the current and previous key. For a lock compatibility matrix, see sys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_RS_U' then 'Occurs when a task is waiting to acquire an Update lock on the current key value, and an Update Range lock between the current and previous key. For a lock compatibility matrix, see sys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_RX_S' then 'Occurs when a task is waiting to acquire a Shared lock on the current key value, and an Exclusive Range lock between the current and previous key. For a lock compatibility matrix, see sys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_RX_U' then 'Occurs when a task is waiting to acquire an Update lock on the current key value, and an Exclusive range lock between the current and previous key. For a lock compatibility matrix, see sys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_RX_X' then 'Occurs when a task is waiting to acquire an Exclusive lock on the current key value, and an Exclusive Range lock between the current and previous key. For a lock compatibility matrix, see sys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_S' then 'Occurs when a task is waiting to acquire a Shared lock. For a lock compatibility matrix, seesys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_SCH_M' then 'Occurs when a task is waiting to acquire a Schema Modify lock. For a lock compatibility matrix, seesys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_SCH_S' then 'Occurs when a task is waiting to acquire a Schema Share lock. For a lock compatibility matrix, seesys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_SIU' then 'Occurs when a task is waiting to acquire a Shared With Intent Update lock. For a lock compatibility matrix, see sys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_SIX' then 'Occurs when a task is waiting to acquire a Shared With Intent Exclusive lock. For a lock compatibility matrix, see sys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_U' then 'Occurs when a task is waiting to acquire an Update lock. For a lock compatibility matrix, seesys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_UIX' then 'Occurs when a task is waiting to acquire an Update With Intent Exclusive lock. For a lock compatibility matrix, see sys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LCK_M_X' then 'Occurs when a task is waiting to acquire an Exclusive lock. For a lock compatibility matrix, seesys.dm_tran_locks (Transact-SQL).'
 
when [W1].[wait_type] = 'LOGBUFFER' then 'Occurs when a task is waiting for space in the log buffer to store a log record. Consistently high values may indicate that the log devices cannot keep up with the amount of log being generated by the server.'
 
when [W1].[wait_type] = 'LOGGENERATION' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'LOGMGR' then 'Occurs when a task is waiting for any outstanding log I/Os to finish before shutting down the log while closing the database.'
 
when [W1].[wait_type] = 'LOGMGR_FLUSH' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'LOGMGR_QUEUE' then 'Occurs while the log writer task waits for work requests.'
 
when [W1].[wait_type] = 'LOGMGR_RESERVE_APPEND' then 'Occurs when a task is waiting to see whether log truncation frees up log space to enable the task to write a new log record. Consider increasing the size of the log file(s) for the affected database to reduce this wait.'
 
when [W1].[wait_type] = 'LOWFAIL_MEMMGR_QUEUE' then 'Occurs while waiting for memory to be available for use.'
 
when [W1].[wait_type] = 'MISCELLANEOUS' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'MSQL_DQ' then 'Occurs when a task is waiting for a distributed query operation to finish. This is used to detect potential Multiple Active Result Set (MARS) application deadlocks. The wait ends when the distributed query call finishes.'
 
when [W1].[wait_type] = 'MSQL_XACT_MGR_MUTEX' then 'Occurs when a task is waiting to obtain ownership of the session transaction manager to perform a session level transaction operation.'
 
when [W1].[wait_type] = 'MSQL_XACT_MUTEX' then 'Occurs during synchronization of transaction usage. A request must acquire the mutex before it can use the transaction.'
 
when [W1].[wait_type] = 'MSQL_XP' then 'Occurs when a task is waiting for an extended stored procedure to end. SQL Server uses this wait state to detect potential MARS application deadlocks. The wait stops when the extended stored procedure call ends.'
 
when [W1].[wait_type] = 'MSSEARCH' then 'Occurs during Full-Text Search calls. This wait ends when the full-text operation completes. It does not indicate contention, but rather the duration of full-text operations.'
 
when [W1].[wait_type] = 'NET_WAITFOR_PACKET' then 'Occurs when a connection is waiting for a network packet during a network read.'
 
when [W1].[wait_type] = 'OLEDB' then 'Occurs when SQL Server calls the SQL Server Native Client OLE DB Provider. This wait type is not used for synchronization. Instead, it indicates the duration of calls to the OLE DB provider.'
 
when [W1].[wait_type] = 'ONDEMAND_TASK_QUEUE' then 'Occurs while a background task waits for high priority system task requests. Long wait times indicate that there have been no high priority requests to process, and should not cause concern.'
 
when [W1].[wait_type] = 'PAGEIOLATCH_DT' then 'Occurs when a task is waiting on a latch for a buffer that is in an I/O request. The latch request is in Destroy mode. Long waits may indicate problems with the disk subsystem.'
 
when [W1].[wait_type] = 'PAGEIOLATCH_EX' then 'Occurs when a task is waiting on a latch for a buffer that is in an I/O request. The latch request is in Exclusive mode. Long waits may indicate problems with the disk subsystem.'
 
when [W1].[wait_type] = 'PAGEIOLATCH_KP' then 'Occurs when a task is waiting on a latch for a buffer that is in an I/O request. The latch request is in Keep mode. Long waits may indicate problems with the disk subsystem.'
 
when [W1].[wait_type] = 'PAGEIOLATCH_NL' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'PAGEIOLATCH_SH' then 'Occurs when a task is waiting on a latch for a buffer that is in an I/O request. The latch request is in Shared mode. Long waits may indicate problems with the disk subsystem.'
 
when [W1].[wait_type] = 'PAGEIOLATCH_UP' then 'Occurs when a task is waiting on a latch for a buffer that is in an I/O request. The latch request is in Update mode. Long waits may indicate problems with the disk subsystem.'
 
when [W1].[wait_type] = 'PAGELATCH_DT' then 'Occurs when a task is waiting on a latch for a buffer that is not in an I/O request. The latch request is in Destroy mode.'
 
when [W1].[wait_type] = 'PAGELATCH_EX' then 'Occurs when a task is waiting on a latch for a buffer that is not in an I/O request. The latch request is in Exclusive mode.'
 
when [W1].[wait_type] = 'PAGELATCH_KP' then 'Occurs when a task is waiting on a latch for a buffer that is not in an I/O request. The latch request is in Keep mode.'
 
when [W1].[wait_type] = 'PAGELATCH_NL' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'PAGELATCH_SH' then 'Occurs when a task is waiting on a latch for a buffer that is not in an I/O request. The latch request is in Shared mode.'
 
when [W1].[wait_type] = 'PAGELATCH_UP' then 'Occurs when a task is waiting on a latch for a buffer that is not in an I/O request. The latch request is in Update mode.'
 
when [W1].[wait_type] = 'PARALLEL_BACKUP_QUEUE' then 'Occurs when serializing output produced by RESTORE HEADERONLY, RESTORE FILELISTONLY, or RESTORE LABELONLY.'
 
when [W1].[wait_type] = 'PREEMPTIVE_ABR' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'PREEMPTIVE_AUDIT_ACCESS_EVENTLOG' then 'Occurs when the SQL Server Operating System (SQLOS) scheduler switches to preemptive mode to write an audit event to the Windows event log.'
 
when [W1].[wait_type] = 'PREEMPTIVE_AUDIT_ACCESS_SECLOG' then 'Occurs when the SQLOS scheduler switches to preemptive mode to write an audit event to the Windows Security log.'
 
when [W1].[wait_type] = 'PREEMPTIVE_CLOSEBACKUPMEDIA' then 'Occurs when the SQLOS scheduler switches to preemptive mode to close backup media.'
 
when [W1].[wait_type] = 'PREEMPTIVE_CLOSEBACKUPTAPE' then 'Occurs when the SQLOS scheduler switches to preemptive mode to close a tape backup device.'
 
when [W1].[wait_type] = 'PREEMPTIVE_CLOSEBACKUPVDIDEVICE' then 'Occurs when the SQLOS scheduler switches to preemptive mode to close a virtual backup device.'
 
when [W1].[wait_type] = 'PREEMPTIVE_CLUSAPI_CLUSTERRESOURCECONTROL' then 'Occurs when the SQLOS scheduler switches to preemptive mode to perform Windows failover cluster operations.'
 
when [W1].[wait_type] = 'PREEMPTIVE_COM_COCREATEINSTANCE' then 'Occurs when the SQLOS scheduler switches to preemptive mode to create a COM object.'
 
when [W1].[wait_type] = 'PREEMPTIVE_HADR_LEASE_MECHANISM' then 'AlwaysOn Availability Groups lease manager scheduling for CSS diagnostics.'
 
when [W1].[wait_type] = 'PREEMPTIVE_SOSTESTING' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'PREEMPTIVE_STRESSDRIVER' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'PREEMPTIVE_TESTING' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'PREEMPTIVE_XETESTING' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'PRINT_ROLLBACK_PROGRESS' then 'Used to wait while user processes are ended in a database that has been transitioned by using the ALTER DATABASE termination clause. For more information, see ALTER DATABASE (Transact-SQL).'
 
when [W1].[wait_type] = 'PWAIT_HADR_CHANGE_NOTIFIER_TERMINATION_SYNC' then 'Occurs when a background task is waiting for the termination of the background task that receives (via polling) Windows Server Failover Clustering notifications. Internal use only.'
 
when [W1].[wait_type] = 'PWAIT_HADR_CLUSTER_INTEGRATION' then 'An append, replace, and/or remove operation is waiting to grab a write lock on an AlwaysOn internal list (such as a list of networks, network addresses, or availability group listeners). Internal use only.'
 
when [W1].[wait_type] = 'PWAIT_HADR_OFFLINE_COMPLETED' then 'An AlwaysOn drop availability group operation is waiting for the target availability group to go offline before destroying Windows Server Failover Clustering objects.'
 
when [W1].[wait_type] = 'PWAIT_HADR_ONLINE_COMPLETED' then 'An AlwaysOn create or failover availability group operation is waiting for the target availability group to come online.'
 
when [W1].[wait_type] = 'PWAIT_HADR_POST_ONLINE_COMPLETED' then 'An AlwaysOn drop availability group operation is waiting for the termination of any background task that was scheduled as part of a previous command. For example, there may be a background task that is transitioning availability databases to the primary r'
 
when [W1].[wait_type] = 'PWAIT_HADR_WORKITEM_COMPLETED' then 'Internal wait by a thread waiting for an async work task to complete. This is an expected wait and is for CSS use.'
 
when [W1].[wait_type] = 'QPJOB_KILL' then 'Indicates that an asynchronous automatic statistics update was canceled by a call to KILL as the update was starting to run. The terminating thread is suspended, waiting for it to start listening for KILL commands. A good value is less than one second.'
 
when [W1].[wait_type] = 'QPJOB_WAITFOR_ABORT' then 'Indicates that an asynchronous automatic statistics update was canceled by a call to KILL when it was running. The update has now completed but is suspended until the terminating thread message coordination is complete. This is an ordinary but rare state,'
 
when [W1].[wait_type] = 'QRY_MEM_GRANT_INFO_MUTEX' then 'Occurs when Query Execution memory management tries to control access to static grant information list. This state lists information about the current granted and waiting memory requests. This state is a simple access control state. There should never be '
 
when [W1].[wait_type] = 'QUERY_ERRHDL_SERVICE_DONE' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'QUERY_EXECUTION_INDEX_SORT_EVENT_OPEN' then 'Occurs in certain cases when offline create index build is run in parallel, and the different worker threads that are sorting synchronize access to the sort files.'
 
when [W1].[wait_type] = 'QUERY_NOTIFICATION_MGR_MUTEX' then 'Occurs during synchronization of the garbage collection queue in the Query Notification Manager.'
 
when [W1].[wait_type] = 'QUERY_NOTIFICATION_SUBSCRIPTION_MUTEX' then 'Occurs during state synchronization for transactions in Query Notifications.'
 
when [W1].[wait_type] = 'QUERY_NOTIFICATION_TABLE_MGR_MUTEX' then 'Occurs during internal synchronization within the Query Notification Manager.'
 
when [W1].[wait_type] = 'QUERY_NOTIFICATION_UNITTEST_MUTEX' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'QUERY_OPTIMIZER_PRINT_MUTEX' then 'Occurs during synchronization of query optimizer diagnostic output production. This wait type only occurs if diagnostic settings have been enabled under direction of Microsoft Product Support.'
 
when [W1].[wait_type] = 'QUERY_TRACEOUT' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'QUERY_WAIT_ERRHDL_SERVICE' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'RECOVER_CHANGEDB' then 'Occurs during synchronization of database status in warm standby database.'
 
when [W1].[wait_type] = 'REPL_CACHE_ACCESS' then 'Occurs during synchronization on a replication article cache. During these waits, the replication log reader stalls, and data definition language (DDL) statements on a published table are blocked.'
 
when [W1].[wait_type] = 'REPL_SCHEMA_ACCESS' then 'Occurs during synchronization of replication schema version information. This state exists when DDL statements are executed on the replicated object, and when the log reader builds or consumes versioned schema based on DDL occurrence.'
 
when [W1].[wait_type] = 'REPLICA_WRITES' then 'Occurs while a task waits for completion of page writes to database snapshots or DBCC replicas.'
 
when [W1].[wait_type] = 'REQUEST_DISPENSER_PAUSE' then 'Occurs when a task is waiting for all outstanding I/O to complete, so that I/O to a file can be frozen for snapshot backup.'
 
when [W1].[wait_type] = 'REQUEST_FOR_DEADLOCK_SEARCH' then 'Occurs while the deadlock monitor waits to start the next deadlock search. This wait is expected between deadlock detections, and lengthy total waiting time on this resource does not indicate a problem.'
 
when [W1].[wait_type] = 'RESMGR_THROTTLED' then 'Occurs when a new request comes in and is throttled based on the GROUP_MAX_REQUESTS setting.'
 
when [W1].[wait_type] = 'RESOURCE_QUEUE' then 'Occurs during synchronization of various internal resource queues.'
 
when [W1].[wait_type] = 'RESOURCE_SEMAPHORE' then 'Occurs when a query memory request cannot be granted immediately due to other concurrent queries. High waits and wait times may indicate excessive number of concurrent queries, or excessive memory request amounts.'
 
when [W1].[wait_type] = 'RESOURCE_SEMAPHORE_MUTEX' then 'Occurs while a query waits for its request for a thread reservation to be fulfilled. It also occurs when synchronizing query compile and memory grant requests.'
 
when [W1].[wait_type] = 'RESOURCE_SEMAPHORE_QUERY_COMPILE' then 'Occurs when the number of concurrent query compilations reaches a throttling limit. High waits and wait times may indicate excessive compilations, recompiles, or uncachable plans.'
 
when [W1].[wait_type] = 'RESOURCE_SEMAPHORE_SMALL_QUERY' then 'Occurs when memory request by a small query cannot be granted immediately due to other concurrent queries. Wait time should not exceed more than a few seconds, because the server transfers the request to the main query memory pool if it fails to grant the'
 
when [W1].[wait_type] = 'SEC_DROP_TEMP_KEY' then 'Occurs after a failed attempt to drop a temporary security key before a retry attempt.'
 
when [W1].[wait_type] = 'SECURITY_MUTEX' then 'Occurs when there is a wait for mutexes that control access to the global list of Extensible Key Management (EKM) cryptographic providers and the session-scoped list of EKM sessions.'
 
when [W1].[wait_type] = 'SEQUENTIAL_GUID' then 'Occurs while a new sequential GUID is being obtained.'
 
when [W1].[wait_type] = 'SERVER_IDLE_CHECK' then 'Occurs during synchronization of SQL Server instance idle status when a resource monitor is attempting to declare a SQL Server instance as idle or trying to wake up.'
 
when [W1].[wait_type] = 'SHUTDOWN' then 'Occurs while a shutdown statement waits for active connections to exit.'
 
when [W1].[wait_type] = 'SLEEP_BPOOL_FLUSH' then 'Occurs when a checkpoint is throttling the issuance of new I/Os in order to avoid flooding the disk subsystem.'
 
when [W1].[wait_type] = 'SLEEP_DBSTARTUP' then 'Occurs during database startup while waiting for all databases to recover.'
 
when [W1].[wait_type] = 'SLEEP_DCOMSTARTUP' then 'Occurs once at most during SQL Server instance startup while waiting for DCOM initialization to complete.'
 
when [W1].[wait_type] = 'SLEEP_MSDBSTARTUP' then 'Occurs when SQL Trace waits for the msdb database to complete startup.'
 
when [W1].[wait_type] = 'SLEEP_SYSTEMTASK' then 'Occurs during the start of a background task while waiting for tempdb to complete startup.'
 
when [W1].[wait_type] = 'SLEEP_TASK' then 'Occurs when a task sleeps while waiting for a generic event to occur.'
 
when [W1].[wait_type] = 'SLEEP_TEMPDBSTARTUP' then 'Occurs while a task waits for tempdb to complete startup.'
 
when [W1].[wait_type] = 'SNI_CRITICAL_SECTION' then 'Occurs during internal synchronization within SQL Server networking components.'
 
when [W1].[wait_type] = 'SNI_HTTP_WAITFOR_0_DISCON' then 'Occurs during SQL Server shutdown, while waiting for outstanding HTTP connections to exit.'
 
when [W1].[wait_type] = 'SNI_LISTENER_ACCESS' then 'Occurs while waiting for non-uniform memory access (NUMA) nodes to update state change. Access to state change is serialized.'
 
when [W1].[wait_type] = 'SNI_TASK_COMPLETION' then 'Occurs when there is a wait for all tasks to finish during a NUMA node state change.'
 
when [W1].[wait_type] = 'SOAP_READ' then 'Occurs while waiting for an HTTP network read to complete.'
 
when [W1].[wait_type] = 'SOAP_WRITE' then 'Occurs while waiting for an HTTP network write to complete.'
 
when [W1].[wait_type] = 'SOS_CALLBACK_REMOVAL' then 'Occurs while performing synchronization on a callback list in order to remove a callback. It is not expected for this counter to change after server initialization is completed.'
 
when [W1].[wait_type] = 'SOS_DISPATCHER_MUTEX' then 'Occurs during internal synchronization of the dispatcher pool. This includes when the pool is being adjusted.'
 
when [W1].[wait_type] = 'SOS_LOCALALLOCATORLIST' then 'Occurs during internal synchronization in the SQL Server memory manager.'
 
when [W1].[wait_type] = 'SOS_MEMORY_USAGE_ADJUSTMENT' then 'Occurs when memory usage is being adjusted among pools.'
 
when [W1].[wait_type] = 'SOS_OBJECT_STORE_DESTROY_MUTEX' then 'Occurs during internal synchronization in memory pools when destroying objects from the pool.'
 
when [W1].[wait_type] = 'SOS_PROCESS_AFFINITY_MUTEX' then 'Occurs during synchronizing of access to process affinity settings.'
 
when [W1].[wait_type] = 'SOS_RESERVEDMEMBLOCKLIST' then 'Occurs during internal synchronization in the SQL Server memory manager.'
 
when [W1].[wait_type] = 'SOS_SCHEDULER_YIELD' then 'Occurs when a task voluntarily yields the scheduler for other tasks to execute. During this wait the task is waiting for its quantum to be renewed.'
 
when [W1].[wait_type] = 'SOS_SMALL_PAGE_ALLOC' then 'Occurs during the allocation and freeing of memory that is managed by some memory objects.'
 
when [W1].[wait_type] = 'SOS_STACKSTORE_INIT_MUTEX' then 'Occurs during synchronization of internal store initialization.'
 
when [W1].[wait_type] = 'SOS_SYNC_TASK_ENQUEUE_EVENT' then 'Occurs when a task is started in a synchronous manner. Most tasks in SQL Server are started in an asynchronous manner, in which control returns to the starter immediately after the task request has been placed on the work queue.'
 
when [W1].[wait_type] = 'SOS_VIRTUALMEMORY_LOW' then 'Occurs when a memory allocation waits for a resource manager to free up virtual memory.'
 
when [W1].[wait_type] = 'SOSHOST_EVENT' then 'Occurs when a hosted component, such as CLR, waits on a SQL Server event synchronization object.'
 
when [W1].[wait_type] = 'SOSHOST_INTERNAL' then 'Occurs during synchronization of memory manager callbacks used by hosted components, such as CLR.'
 
when [W1].[wait_type] = 'SOSHOST_MUTEX' then 'Occurs when a hosted component, such as CLR, waits on a SQL Server mutex synchronization object.'
 
when [W1].[wait_type] = 'SOSHOST_RWLOCK' then 'Occurs when a hosted component, such as CLR, waits on a SQL Server reader-writer synchronization object.'
 
when [W1].[wait_type] = 'SOSHOST_SEMAPHORE' then 'Occurs when a hosted component, such as CLR, waits on a SQL Server semaphore synchronization object.'
 
when [W1].[wait_type] = 'SOSHOST_SLEEP' then 'Occurs when a hosted task sleeps while waiting for a generic event to occur. Hosted tasks are used by hosted components such as CLR.'
 
when [W1].[wait_type] = 'SOSHOST_TRACELOCK' then 'Occurs during synchronization of access to trace streams.'
 
when [W1].[wait_type] = 'SOSHOST_WAITFORDONE' then 'Occurs when a hosted component, such as CLR, waits for a task to complete.'
 
when [W1].[wait_type] = 'SQLCLR_APPDOMAIN' then 'Occurs while CLR waits for an application domain to complete startup.'
 
when [W1].[wait_type] = 'SQLCLR_ASSEMBLY' then 'Occurs while waiting for access to the loaded assembly list in the appdomain.'
 
when [W1].[wait_type] = 'SQLCLR_DEADLOCK_DETECTION' then 'Occurs while CLR waits for deadlock detection to complete.'
 
when [W1].[wait_type] = 'SQLCLR_QUANTUM_PUNISHMENT' then 'Occurs when a CLR task is throttled because it has exceeded its execution quantum. This throttling is done in order to reduce the effect of this resource-intensive task on other tasks.'
 
when [W1].[wait_type] = 'SQLSORT_NORMMUTEX' then 'Occurs during internal synchronization, while initializing internal sorting structures.'
 
when [W1].[wait_type] = 'SQLSORT_SORTMUTEX' then 'Occurs during internal synchronization, while initializing internal sorting structures.'
 
when [W1].[wait_type] = 'SQLTRACE_BUFFER_FLUSH' then 'Occurs when a task is waiting for a background task to flush trace buffers to disk every four seconds.'
 
when [W1].[wait_type] = 'SQLTRACE_LOCK' then 'Occurs during synchronization on trace buffers during a file trace.'
 
when [W1].[wait_type] = 'SQLTRACE_SHUTDOWN' then 'Occurs while trace shutdown waits for outstanding trace events to complete.'
 
when [W1].[wait_type] = 'SQLTRACE_WAIT_ENTRIES' then 'Occurs while a SQL Trace event queue waits for packets to arrive on the queue.'
 
when [W1].[wait_type] = 'SRVPROC_SHUTDOWN' then 'Occurs while the shutdown process waits for internal resources to be released to shutdown cleanly.'
 
when [W1].[wait_type] = 'TEMPOBJ' then 'Occurs when temporary object drops are synchronized. This wait is rare, and only occurs if a task has requested exclusive access for temp table drops.'
 
when [W1].[wait_type] = 'THREADPOOL' then 'Occurs when a task is waiting for a worker to run on. This can indicate that the maximum worker setting is too low, or that batch executions are taking unusually long, thus reducing the number of workers available to satisfy other batches.'
 
when [W1].[wait_type] = 'TIMEPRIV_TIMEPERIOD' then 'Occurs during internal synchronization of the Extended Events timer.'
 
when [W1].[wait_type] = 'TRACEWRITE' then 'Occurs when the SQL Trace rowset trace provider waits for either a free buffer or a buffer with events to process.'
 
when [W1].[wait_type] = 'TRAN_MARKLATCH_DT' then 'Occurs when waiting for a destroy mode latch on a transaction mark latch. Transaction mark latches are used for synchronization of commits with marked transactions.'
 
when [W1].[wait_type] = 'TRAN_MARKLATCH_EX' then 'Occurs when waiting for an exclusive mode latch on a marked transaction. Transaction mark latches are used for synchronization of commits with marked transactions.'
 
when [W1].[wait_type] = 'TRAN_MARKLATCH_KP' then 'Occurs when waiting for a keep mode latch on a marked transaction. Transaction mark latches are used for synchronization of commits with marked transactions.'
 
when [W1].[wait_type] = 'TRAN_MARKLATCH_NL' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'TRAN_MARKLATCH_SH' then 'Occurs when waiting for a shared mode latch on a marked transaction. Transaction mark latches are used for synchronization of commits with marked transactions.'
 
when [W1].[wait_type] = 'TRAN_MARKLATCH_UP' then 'Occurs when waiting for an update mode latch on a marked transaction. Transaction mark latches are used for synchronization of commits with marked transactions.'
 
when [W1].[wait_type] = 'TRANSACTION_MUTEX' then 'Occurs during synchronization of access to a transaction by multiple batches.'
 
when [W1].[wait_type] = 'UTIL_PAGE_ALLOC' then 'Occurs when transaction log scans wait for memory to be available during memory pressure.'
 
when [W1].[wait_type] = 'VIA_ACCEPT' then 'Occurs when a Virtual Interface Adapter (VIA) provider connection is completed during startup.'
 
when [W1].[wait_type] = 'VIEW_DEFINITION_MUTEX' then 'Occurs during synchronization on access to cached view definitions.'
 
when [W1].[wait_type] = 'WAIT_FOR_RESULTS' then 'Occurs when waiting for a query notification to be triggered.'
 
when [W1].[wait_type] = 'WAITFOR' then 'Occurs as a result of a WAITFOR Transact-SQL statement. The duration of the wait is determined by the parameters to the statement. This is a user-initiated wait.'
 
when [W1].[wait_type] = 'WAITFOR_TASKSHUTDOWN' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'WAITSTAT_MUTEX' then 'Occurs during synchronization of access to the collection of statistics used to populate sys.dm_os_wait_stats.'
 
when [W1].[wait_type] = 'WCC' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'WORKTBL_DROP' then 'Occurs while pausing before retrying, after a failed worktable drop.'
 
when [W1].[wait_type] = 'WRITE_COMPLETION' then 'Occurs when a write operation is in progress.'
 
when [W1].[wait_type] = 'WRITELOG' then 'Occurs while waiting for a log flush to complete. Common operations that cause log flushes are checkpoints and transaction commits.'
 
when [W1].[wait_type] = 'XACT_OWN_TRANSACTION' then 'Occurs while waiting to acquire ownership of a transaction.'
 
when [W1].[wait_type] = 'XACT_RECLAIM_SESSION' then 'Occurs while waiting for the current owner of a session to release ownership of the session.'
 
when [W1].[wait_type] = 'XACTLOCKINFO' then 'Occurs during synchronization of access to the list of locks for a transaction. In addition to the transaction itself, the list of locks is accessed by operations such as deadlock detection and lock migration during page splits.'
 
when [W1].[wait_type] = 'XACTWORKSPACE_MUTEX' then 'Occurs during synchronization of defections from a transaction, as well as the number of database locks between enlist members of a transaction.'
 
when [W1].[wait_type] = 'XE_BUFFERMGR_ALLPROCESSED_EVENT' then 'Occurs when Extended Events session buffers are flushed to targets. This wait occurs on a background thread.'
 
when [W1].[wait_type] = 'XE_BUFFERMGR_FREEBUF_EVENT' then 'Occurs when either of the following conditions is true: An Extended Events session is configured for no event loss, and all buffers in the session are currently full. This can indicate that the buffers for an Extende'
 
when [W1].[wait_type] = 'XE_DISPATCHER_CONFIG_SESSION_LIST' then 'Occurs when an Extended Events session that is using asynchronous targets is started or stopped. This wait indicates either of the following: An Extended Events session is registering with a background thread pool.'
 
when [W1].[wait_type] = 'XE_DISPATCHER_JOIN' then 'Occurs when a background thread that is used for Extended Events sessions is terminating.'
 
when [W1].[wait_type] = 'XE_DISPATCHER_WAIT' then 'Occurs when a background thread that is used for Extended Events sessions is waiting for event buffers to process.'
 
when [W1].[wait_type] = 'XE_MODULEMGR_SYNC' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'XE_OLS_LOCK' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'XE_PACKAGE_LOCK_BACKOFF' then 'Identified for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'FT_COMPROWSET_RWLOCK' then 'Full-text is waiting on fragment metadata operation. Documented for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'FT_IFTS_RWLOCK' then 'Full-text is waiting on internal synchronization. Documented for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'FT_IFTS_SCHEDULER_IDLE_WAIT' then 'Full-text scheduler sleep wait type. The scheduler is idle.'
 
when [W1].[wait_type] = 'FT_IFTSHC_MUTEX' then 'Full-text is waiting on an fdhost control operation. Documented for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'FT_IFTSISM_MUTEX' then 'Full-text is waiting on communication operation. Documented for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
when [W1].[wait_type] = 'FT_MASTER_MERGE' then 'Full-text is waiting on master merge operation. Documented for informational purposes only. Not supported. Future compatibility is not guaranteed.'
 
ELSE 'Wait type is not documented in http://msdn.microsoft.com/en-us/library/ms179984.aspx'
 
END,
 
CAST ([W1].[WaitS] AS DECIMAL(14, 2)) AS [Wait_S],
CAST ([W1].[ResourceS] AS DECIMAL(14, 2)) AS [Resource_S],
CAST ([W1].[SignalS] AS DECIMAL(14, 2)) AS [Signal_S],
[W1].[WaitCount] AS [WaitCount],
CAST ([W1].[Percentage] AS DECIMAL(4, 2)) AS [Percentage],
CAST (([W1].[WaitS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgWait_S],
CAST (([W1].[ResourceS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgRes_S],
CAST (([W1].[SignalS] / [W1].[WaitCount]) AS DECIMAL (14, 4)) AS [AvgSig_S]
FROM [Waits] AS [W1]
INNER JOIN [Waits] AS [W2]
ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum], [W1].[wait_type], [W1].[WaitS],
[W1].[ResourceS], [W1].[SignalS], [W1].[WaitCount], [W1].[Percentage]
HAVING SUM ([W2].[Percentage]) - [W1].[Percentage] < 95; -- percentage threshold
 
GO
