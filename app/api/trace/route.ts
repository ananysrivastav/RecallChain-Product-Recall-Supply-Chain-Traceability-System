// app/api/trace/route.ts
import { NextResponse } from 'next/server';
import pool from '@/lib/db';

export async function GET(req: Request) {
  const { searchParams } = new URL(req.url);
  const recallId = searchParams.get('recallId');

  if (!recallId) {
    return NextResponse.json({ error: 'recallId query parameter is required' }, { status: 400 });
  }

  try {
    const [customers] = await pool.query(
      'SELECT * FROM vw_recall_affected_customers WHERE recall_id = ?',
      [recallId]
    );

    const [exposure] = await pool.query(
      'SELECT * FROM vw_recall_stock_exposure WHERE recall_id = ?',
      [recallId]
    );

    return NextResponse.json({
      recallId,
      customers,
      stockExposure: exposure
    });
  } catch (error: any) {
    return NextResponse.json({ error: error.message }, { status: 500 });
  }
}