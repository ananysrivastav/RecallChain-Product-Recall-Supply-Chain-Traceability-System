// app/api/recalls/route.ts
import { NextResponse } from 'next/server';
import pool from '@/lib/db';

export async function GET() {
  try {
    // Uses pre-built view from your SQL script
    const [rows] = await pool.query('SELECT * FROM vw_active_recalls');
    return NextResponse.json(rows);
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}

export async function POST(req: Request) {
  const connection = await pool.getConnection();
  try {
    const { batchId, reason, severity, userId } = await req.json();

    if (!batchId || !reason || !severity) {
      return NextResponse.json({ error: 'Missing batchId, reason, or severity' }, { status: 400 });
    }

    // Call your exact database stored procedure
    await connection.query('CALL sp_issue_recall(?, ?, ?, ?, @p_recall_id)', [
      Number(batchId),
      reason,
      severity.toLowerCase(),
      userId || 1
    ]);

    const [outResult]: any = await connection.query('SELECT @p_recall_id AS recall_id');
    const recallId = outResult[0]?.recall_id;

    return NextResponse.json({
      success: true,
      message: `Recall #${recallId} generated. Triggers automatically quarantined batch and staged notifications.`,
      recallId
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  } finally {
    connection.release();
  }
}