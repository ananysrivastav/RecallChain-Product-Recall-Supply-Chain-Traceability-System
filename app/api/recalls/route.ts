// app/api/recalls/route.ts
import { NextResponse } from 'next/server';
import pool from '@/lib/db';

export async function GET() {
  try {
    const [rows] = await pool.query('SELECT * FROM vw_active_recalls');
    return NextResponse.json(rows);
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : 'Internal Server Error';
    console.error('API Error GET /api/recalls:', message);
    return NextResponse.json({ error: message }, { status: 500 });
  }
}

export async function POST(req: Request) {
  let connection;
  try {
    const body = await req.json();
    const { batchId, reason, severity, userId } = body;

    if (!batchId || !reason || !severity) {
      return NextResponse.json(
        { error: 'Missing batchId, reason, or severity' },
        { status: 400 }
      );
    }

    connection = await pool.getConnection();

    // Set application user session variable for audit triggers
    await connection.query('SET @app_user_id = ?', [userId || 1]);

    // Call stored procedure
    await connection.query('CALL sp_issue_recall(?, ?, ?, ?, @p_recall_id)', [
      Number(batchId),
      reason,
      severity.toLowerCase(),
      userId || 1,
    ]);

    // Fetch the OUT parameter result
    const [rows]: any = await connection.query(
      'SELECT @p_recall_id AS recall_id'
    );
    const recallId = rows[0]?.recall_id;

    return NextResponse.json({
      success: true,
      message: `Recall #${recallId} created successfully.`,
      recallId,
    });
  } catch (error: unknown) {
    const message =
      error instanceof Error ? error.message : 'Internal Server Error';
    console.error('API Error POST /api/recalls:', message);
    return NextResponse.json({ error: message }, { status: 500 });
  } finally {
    if (connection) connection.release();
  }
}
