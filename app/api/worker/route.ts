// app/api/worker/route.ts
import { NextResponse } from 'next/server';
import { runOSPriorityWorker } from '@/lib/osEngine';
import pool from '@/lib/db';

export async function POST() {
  try {
    const workerResult = await runOSPriorityWorker(`OS-Worker-${Math.floor(1000 + Math.random() * 9000)}`);
    return NextResponse.json(workerResult);
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function GET() {
  try {
    // Fetch queue status and pending items
    const [pending]: any = await pool.query(`
      SELECT n.notification_id, n.channel, n.status, r.severity, c.name as customer_name, n.created_at
      FROM notifications n
      JOIN recalls r ON n.recall_id = r.recall_id
      JOIN customers c ON n.customer_id = c.customer_id
      ORDER BY n.created_at DESC
      LIMIT 10
    `);
    return NextResponse.json(pending);
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}
