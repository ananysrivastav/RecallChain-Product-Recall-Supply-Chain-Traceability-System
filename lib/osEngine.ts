// lib/osEngine.ts
import pool from './db';

export interface SchedulerJobResult {
  workerId: string;
  processedCount: number;
  executionTimeMs: number;
  tasks: Array<{
    notification_id: number;
    channel: string;
    customer_name: string;
    severity: string;
  }>;
}

export async function runOSPriorityWorker(workerId: string = `Worker-Thread-${process.pid}`): Promise<SchedulerJobResult> {
  const connection = await pool.getConnection();
  const startTime = performance.now();

  try {
    await connection.beginTransaction();

    // OS PRIORITY SCHEDULING & MUTEX (Critical Section):
    // Prioritize critical recalls over high, medium, and low recalls.
    // Row-level lock prevents race conditions between parallel background workers.
    const [tasks]: any = await connection.query(`
      SELECT 
        n.notification_id, 
        n.channel, 
        c.name AS customer_name,
        r.severity,
        r.recall_id
      FROM notifications n
      JOIN customers c ON n.customer_id = c.customer_id
      JOIN recalls r ON n.recall_id = r.recall_id
      WHERE n.status = 'pending'
      ORDER BY 
        CASE r.severity
          WHEN 'critical' THEN 1
          WHEN 'high' THEN 2
          WHEN 'medium' THEN 3
          WHEN 'low' THEN 4
          ELSE 5
        END ASC,
        n.created_at ASC
      LIMIT 5
      FOR UPDATE
    `);

    if (!tasks || tasks.length === 0) {
      await connection.rollback();
      return { workerId, processedCount: 0, executionTimeMs: 0, tasks: [] };
    }

    const taskIds = tasks.map((t: any) => t.notification_id);

    // Context Switch / State change to 'processing'
    await connection.query(
      `UPDATE notifications SET status = 'processing' WHERE notification_id IN (?)`,
      [taskIds]
    );

    await connection.commit();

    // Simulate I/O dispatch work burst
    await new Promise((resolve) => setTimeout(resolve, 250));

    // Complete Tasks
    await pool.query(
      `UPDATE notifications SET status = 'sent', sent_at = NOW() WHERE notification_id IN (?)`,
      [taskIds]
    );

    const endTime = performance.now();
    const duration = parseFloat((endTime - startTime).toFixed(2));

    // Telemetry log to audit_logs
    await pool.query(`
      INSERT INTO audit_logs (table_name, record_id, action, new_values, changed_by)
      VALUES (
        'notifications_scheduler',
        ?,
        'UPDATE',
        JSON_OBJECT('worker', ?, 'processed_count', ?, 'execution_ms', ?),
        1
      )
    `, [taskIds.join(','), workerId, taskIds.length, duration]);

    return {
      workerId,
      processedCount: taskIds.length,
      executionTimeMs: duration,
      tasks
    };
  } catch (error) {
    await connection.rollback();
    throw error;
  } finally {
    connection.release();
  }
}