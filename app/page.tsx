'use client';

import React, { useState, useEffect } from 'react';
import { 
  ShieldAlert, 
  Cpu, 
  Database, 
  Layers, 
  GitFork, 
  CheckCircle2, 
  Clock, 
  AlertTriangle, 
  Play, 
  RefreshCw, 
  Building2, 
  Warehouse, 
  Store, 
  Users, 
  Terminal,
  Activity
} from 'lucide-react';

interface ActiveRecall {
  recall_id: number;
  severity: 'low' | 'medium' | 'high' | 'critical';
  status: string;
  recall_date: string;
  reason: string;
  batch_code: string;
  product_name: string;
}

interface NotificationTask {
  notification_id: number;
  channel: string;
  status: string;
  severity: string;
  customer_name: string;
  created_at: string;
}

interface WorkerTelemetry {
  workerId: string;
  processedCount: number;
  executionTimeMs: number;
}

export default function EvaluatorRecallDashboard() {
  const [recalls, setRecalls] = useState<ActiveRecall[]>([]);
  const [queue, setQueue] = useState<NotificationTask[]>([]);
  const [loading, setLoading] = useState(false);
  const [workerLogs, setWorkerLogs] = useState<WorkerTelemetry | null>(null);

  // Form State
  const [batchId, setBatchId] = useState('1');
  const [reason, setReason] = useState('');
  const [severity, setSeverity] = useState<'low' | 'medium' | 'high' | 'critical'>('critical');

  // Traceability Inspection State
  const [selectedRecall, setSelectedRecall] = useState<ActiveRecall | null>(null);
  const [traceData, setTraceData] = useState<{ customers: any[]; stockExposure: any[] } | null>(null);
  const [isTracing, setIsTracing] = useState(false);

  const fetchDashboardData = async () => {
    try {
      const [resRecalls, resQueue] = await Promise.all([
        fetch('/api/recalls'),
        fetch('/api/worker')
      ]);
      const dataRecalls = await resRecalls.json();
      const dataQueue = await resQueue.json();
      
      if (Array.isArray(dataRecalls)) setRecalls(dataRecalls);
      if (Array.isArray(dataQueue)) setQueue(dataQueue);
    } catch (err) {
      console.error('Failed to sync state', err);
    }
  };

  useEffect(() => {
    fetchDashboardData();
    const interval = setInterval(fetchDashboardData, 4000); // Polling for live presentation
    return () => clearInterval(interval);
  }, []);

  const handleIssueRecall = async (e: React.FormEvent) => {
    e.preventDefault();
    if (!reason.trim()) return alert('Please describe the root defect reason');

    setLoading(true);
    try {
      const res = await fetch('/api/recalls', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({ batchId, reason, severity, userId: 1 })
      });
      const data = await res.json();
      if (res.ok) {
        setReason('');
        await fetchDashboardData();
      } else {
        alert(`DB Error: ${data.error}`);
      }
    } catch (err: any) {
      alert(`API Failed: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const handleRunOSWorker = async () => {
    setLoading(true);
    try {
      const res = await fetch('/api/worker', { method: 'POST' });
      const data = await res.json();
      setWorkerLogs(data);
      await fetchDashboardData();
    } catch (err: any) {
      alert(`OS Worker Execution Failed: ${err.message}`);
    } finally {
      setLoading(false);
    }
  };

  const inspectTraceChain = async (recall: ActiveRecall) => {
    setSelectedRecall(recall);
    setIsTracing(true);
    try {
      const res = await fetch(`/api/trace?recallId=${recall.recall_id}`);
      const data = await res.json();
      setTraceData(data);
    } catch (err) {
      console.error(err);
    } finally {
      setIsTracing(false);
    }
  };

  // OS Metrics derived from state
  const pendingJobsCount = queue.filter(q => q.status === 'pending').length;
  const criticalCount = queue.filter(q => q.severity === 'critical' && q.status === 'pending').length;

  return (
    <div className="min-h-screen bg-[#090D16] text-slate-100 font-sans antialiased selection:bg-blue-600 selection:text-white">
      
      {/* Top Professional Header */}
      <nav className="border-b border-slate-800/80 bg-[#0C1222]/80 backdrop-blur-md sticky top-0 z-50 px-6 py-4">
        <div className="max-w-7xl mx-auto flex flex-col md:flex-row md:items-center justify-between gap-4">
          <div className="flex items-center gap-3">
            <div className="h-10 w-10 rounded-xl bg-gradient-to-tr from-rose-600 to-indigo-600 p-0.5 shadow-lg shadow-rose-950/40">
              <div className="h-full w-full bg-[#090D16] rounded-[10px] flex items-center justify-center">
                <GitFork className="h-5 w-5 text-rose-500" />
              </div>
            </div>
            <div>
              <div className="flex items-center gap-2">
                <span className="text-xl font-bold tracking-tight text-white">RecallChain</span>
                <span className="text-[10px] bg-indigo-500/10 text-indigo-400 border border-indigo-500/20 px-2 py-0.5 rounded-full font-mono uppercase font-semibold">
                  OS & DBMS Core
                </span>
              </div>
              <p className="text-xs text-slate-400">Traceability Graph & Preemptive Concurrency Scheduler</p>
            </div>
          </div>

          <div className="flex items-center gap-3">
            <div className="hidden sm:flex items-center gap-2 bg-slate-900 border border-slate-800 px-3 py-1.5 rounded-lg text-xs font-mono text-slate-400">
              <span className="h-2 w-2 rounded-full bg-emerald-500 animate-pulse"></span>
              <span>InnoDB Pool: Active</span>
            </div>
            <button 
              onClick={fetchDashboardData}
              className="p-2 bg-slate-900 hover:bg-slate-800 text-slate-300 border border-slate-800 rounded-lg transition"
              title="Refresh State"
            >
              <RefreshCw className="h-4 w-4" />
            </button>
          </div>
        </div>
      </nav>

      <main className="max-w-7xl mx-auto p-6 space-y-6">

        {/* Operating System & DBMS Telemetry HUD */}
        <section className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-4 gap-4">
          <div className="bg-slate-900/60 border border-slate-800/80 rounded-xl p-4 backdrop-blur shadow-sm">
            <div className="flex items-center justify-between text-slate-400 text-xs font-medium mb-2">
              <span>Ready Queue Depth</span>
              <Activity className="h-4 w-4 text-indigo-400" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-white">{pendingJobsCount}</span>
              <span className="text-xs text-slate-400">tasks waiting</span>
            </div>
            <div className="text-[11px] text-indigo-400 mt-2 font-mono flex items-center gap-1">
              <span>• Priority Heap: Ready</span>
            </div>
          </div>

          <div className="bg-slate-900/60 border border-slate-800/80 rounded-xl p-4 backdrop-blur shadow-sm">
            <div className="flex items-center justify-between text-slate-400 text-xs font-medium mb-2">
              <span>Preemption Status</span>
              <ShieldAlert className="h-4 w-4 text-rose-400" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-rose-400">{criticalCount}</span>
              <span className="text-xs text-slate-400">Critical (Priority 1)</span>
            </div>
            <div className="text-[11px] text-slate-400 mt-2">Critical jobs preempt low priority</div>
          </div>

          <div className="bg-slate-900/60 border border-slate-800/80 rounded-xl p-4 backdrop-blur shadow-sm">
            <div className="flex items-center justify-between text-slate-400 text-xs font-medium mb-2">
              <span>Worker Burst Time</span>
              <Cpu className="h-4 w-4 text-amber-400" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-amber-400">
                {workerLogs?.executionTimeMs ? `${workerLogs.executionTimeMs}` : '0.00'}
              </span>
              <span className="text-xs text-slate-400">ms execution</span>
            </div>
            <div className="text-[11px] text-slate-400 mt-2 font-mono truncate">
              {workerLogs?.workerId || 'No active cycle executed'}
            </div>
          </div>

          <div className="bg-slate-900/60 border border-slate-800/80 rounded-xl p-4 backdrop-blur shadow-sm">
            <div className="flex items-center justify-between text-slate-400 text-xs font-medium mb-2">
              <span>ACID Mutex Locks</span>
              <Database className="h-4 w-4 text-emerald-400" />
            </div>
            <div className="flex items-baseline gap-2">
              <span className="text-2xl font-bold font-mono text-emerald-400">100%</span>
              <span className="text-xs text-slate-400">Isolated</span>
            </div>
            <div className="text-[11px] text-emerald-500/80 mt-2 flex items-center gap-1 font-mono">
              <span>FOR UPDATE Row Locks</span>
            </div>
          </div>
        </section>

        {/* Action Panel & Interactive Trigger Section */}
        <section className="grid grid-cols-1 lg:grid-cols-12 gap-6">
          
          {/* Issue Recall Form (DBMS Stored Procedure Trigger) */}
          <div className="lg:col-span-5 bg-[#0C1222] border border-slate-800 rounded-2xl p-5 shadow-xl flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between pb-3 mb-4 border-b border-slate-800">
                <div className="flex items-center gap-2">
                  <AlertTriangle className="h-4 w-4 text-rose-500" />
                  <h2 className="font-semibold text-slate-200 text-sm">Issue Product Recall</h2>
                </div>
                <span className="text-[10px] text-slate-400 font-mono">Stored Procedure: sp_issue_recall</span>
              </div>

              <form onSubmit={handleIssueRecall} className="space-y-4">
                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">Target Batch ID</label>
                  <input
                    type="number"
                    value={batchId}
                    onChange={(e) => setBatchId(e.target.value)}
                    className="w-full bg-[#080D1A] border border-slate-700/80 rounded-lg px-3 py-2 text-sm text-slate-100 focus:outline-none focus:border-rose-500 transition"
                    placeholder="Enter Batch ID (e.g. 1, 2, 3)"
                    required
                  />
                  <span className="text-[10px] text-slate-500 mt-0.5 block">Batch 1: Face Wash, Batch 2 & 3: Honey</span>
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">Defect Analysis Reason</label>
                  <textarea
                    value={reason}
                    onChange={(e) => setReason(e.target.value)}
                    rows={2}
                    className="w-full bg-[#080D1A] border border-slate-700/80 rounded-lg px-3 py-2 text-sm text-slate-100 focus:outline-none focus:border-rose-500 transition"
                    placeholder="E.g. High bacterial count detected in microbiological assay"
                    required
                  />
                </div>

                <div>
                  <label className="block text-xs font-medium text-slate-300 mb-1">OS Scheduler Priority Level</label>
                  <div className="grid grid-cols-4 gap-2">
                    {(['critical', 'high', 'medium', 'low'] as const).map((sev) => (
                      <button
                        type="button"
                        key={sev}
                        onClick={() => setSeverity(sev)}
                        className={`text-xs uppercase font-mono py-2 rounded-lg border transition font-bold ${
                          severity === sev 
                            ? 'bg-rose-500/20 border-rose-500 text-rose-400' 
                            : 'bg-slate-900 border-slate-800 text-slate-400 hover:border-slate-700'
                        }`}
                      >
                        {sev}
                      </button>
                    ))}
                  </div>
                </div>

                <button
                  type="submit"
                  disabled={loading}
                  className="w-full bg-gradient-to-r from-rose-600 to-red-700 hover:from-rose-500 hover:to-red-600 text-white font-medium py-2.5 rounded-xl text-sm transition shadow-lg shadow-rose-950/50 disabled:opacity-50 flex items-center justify-center gap-2"
                >
                  <ShieldAlert className="h-4 w-4" />
                  <span>{loading ? 'Executing Transaction...' : 'Commit Recall Transaction'}</span>
                </button>
              </form>
            </div>

            <div className="mt-4 pt-3 border-t border-slate-800/80 text-[11px] text-slate-500 flex items-center gap-1.5">
              <CheckCircle2 className="h-3.5 w-3.5 text-emerald-500 shrink-0" />
              <span>DB Triggers will automatically cascade: batches $\to$ quarantined, stock blocked.</span>
            </div>
          </div>

          {/* OS Scheduler & Preemption Engine Dispatcher */}
          <div className="lg:col-span-7 bg-[#0C1222] border border-slate-800 rounded-2xl p-5 shadow-xl flex flex-col justify-between">
            <div>
              <div className="flex items-center justify-between pb-3 mb-4 border-b border-slate-800">
                <div className="flex items-center gap-2">
                  <Cpu className="h-4 w-4 text-indigo-400" />
                  <h2 className="font-semibold text-slate-200 text-sm">OS Process Scheduler & Thread Pool</h2>
                </div>
                <span className="text-[10px] text-indigo-400 font-mono bg-indigo-500/10 px-2 py-0.5 rounded border border-indigo-500/20">
                  Priority Queue Algorithm
                </span>
              </div>

              <p className="text-xs text-slate-400 leading-relaxed mb-4">
                The dispatcher simulates an OS CPU scheduler. Tasks queued by SQL triggers are consumed 
                using <code className="text-amber-400 bg-slate-900 px-1 py-0.5 rounded">FOR UPDATE</code> mutual exclusion locks. 
                Higher priority batches preempt lower priority queues.
              </p>

              <div className="bg-[#080D1A] border border-slate-800/80 rounded-xl p-3 mb-4">
                <div className="flex items-center justify-between mb-2">
                  <span className="text-xs font-mono text-slate-400">Ready Queue Buffer</span>
                  <span className="text-xs font-mono text-indigo-400">{queue.length} Tasks in Buffer</span>
                </div>
                
                <div className="space-y-1.5 max-h-36 overflow-y-auto pr-1">
                  {queue.slice(0, 4).map((task) => (
                    <div 
                      key={task.notification_id} 
                      className="flex items-center justify-between bg-slate-900/80 border border-slate-800 px-3 py-1.5 rounded-lg text-xs"
                    >
                      <div className="flex items-center gap-2 font-mono">
                        <span className={`h-2 w-2 rounded-full ${
                          task.severity === 'critical' ? 'bg-rose-500 animate-ping' :
                          task.severity === 'high' ? 'bg-orange-500' : 'bg-yellow-500'
                        }`} />
                        <span className="text-slate-300">#{task.notification_id}</span>
                        <span className="text-slate-400">{task.customer_name}</span>
                      </div>
                      <div className="flex items-center gap-2">
                        <span className="text-[10px] uppercase font-mono px-1.5 py-0.5 bg-slate-800 text-slate-400 rounded">
                          {task.channel}
                        </span>
                        <span className={`text-[10px] uppercase font-mono px-2 py-0.5 rounded font-bold ${
                          task.status === 'sent' ? 'bg-emerald-500/10 text-emerald-400 border border-emerald-500/20' :
                          task.status === 'processing' ? 'bg-amber-500/10 text-amber-400 border border-amber-500/20' :
                          'bg-slate-800 text-slate-400'
                        }`}>
                          {task.status}
                        </span>
                      </div>
                    </div>
                  ))}
                  {queue.length === 0 && (
                    <div className="text-center py-4 text-xs text-slate-600 font-mono">
                      Queue buffer is empty. Issue a recall to populate tasks.
                    </div>
                  )}
                </div>
              </div>
            </div>

            <div className="space-y-3">
              <button
                onClick={handleRunOSWorker}
                disabled={loading || pendingJobsCount === 0}
                className="w-full bg-indigo-600 hover:bg-indigo-500 text-white font-medium py-2.5 rounded-xl text-sm transition shadow-lg shadow-indigo-950/50 disabled:opacity-40 flex items-center justify-center gap-2 font-mono"
              >
                <Play className="h-4 w-4 fill-white" />
                <span>Dispatch OS Thread (Consume Highest Priority)</span>
              </button>

              {workerLogs && (
                <div className="bg-slate-950 border border-indigo-900/40 rounded-xl p-3 flex items-center justify-between text-xs font-mono">
                  <div className="flex items-center gap-2 text-indigo-400">
                    <Terminal className="h-4 w-4" />
                    <span>Thread: {workerLogs.workerId}</span>
                  </div>
                  <div className="text-slate-400">
                    Dispatched: <span className="text-white font-bold">{workerLogs.processedCount} jobs</span>
                  </div>
                  <div className="text-amber-400">
                    Time: <span className="font-bold">{workerLogs.executionTimeMs} ms</span>
                  </div>
                </div>
              )}
            </div>
          </div>
        </section>

        {/* Real-time Recalls & Interactive Trace Tree Visualizer */}
        <section className="bg-[#0C1222] border border-slate-800 rounded-2xl p-5 shadow-xl space-y-4">
          <div className="flex items-center justify-between pb-3 border-b border-slate-800">
            <div className="flex items-center gap-2">
              <Layers className="h-4 w-4 text-blue-400" />
              <h2 className="font-semibold text-slate-200 text-sm">Active Recalled Batches (Live Relational View)</h2>
            </div>
            <span className="text-xs text-slate-400 font-mono">vw_active_recalls</span>
          </div>

          <div className="overflow-x-auto">
            <table className="w-full text-left text-sm text-slate-300">
              <thead className="bg-[#080D1A] text-[11px] uppercase text-slate-400 font-mono tracking-wider">
                <tr>
                  <th className="p-3 rounded-l-lg">Recall ID</th>
                  <th className="p-3">Batch Code</th>
                  <th className="p-3">Product Name</th>
                  <th className="p-3">Priority Severity</th>
                  <th className="p-3">Reason</th>
                  <th className="p-3 text-right rounded-r-lg">Traceability Tree</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-800/60 font-sans">
                {recalls.map((r) => (
                  <tr key={r.recall_id} className="hover:bg-slate-800/30 transition">
                    <td className="p-3 font-mono text-xs font-bold text-slate-400">#{r.recall_id}</td>
                    <td className="p-3 font-mono font-semibold text-white">{r.batch_code}</td>
                    <td className="p-3 text-slate-200">{r.product_name}</td>
                    <td className="p-3">
                      <span className={`text-[10px] px-2 py-0.5 rounded uppercase font-mono font-bold tracking-wider ${
                        r.severity === 'critical' ? 'bg-rose-500/10 text-rose-400 border border-rose-500/30' :
                        r.severity === 'high' ? 'bg-orange-500/10 text-orange-400 border border-orange-500/30' :
                        'bg-yellow-500/10 text-yellow-400 border border-yellow-500/30'
                      }`}>
                        {r.severity}
                      </span>
                    </td>
                    <td className="p-3 text-slate-400 text-xs truncate max-w-sm">{r.reason}</td>
                    <td className="p-3 text-right">
                      <button
                        onClick={() => inspectTraceChain(r)}
                        className={`text-xs px-3 py-1.5 rounded-lg border font-medium transition flex items-center gap-1.5 ml-auto ${
                          selectedRecall?.recall_id === r.recall_id
                            ? 'bg-blue-600 border-blue-500 text-white shadow-md shadow-blue-900/40'
                            : 'bg-slate-900 hover:bg-slate-800 border-slate-700 text-slate-300'
                        }`}
                      >
                        <GitFork className="h-3 w-3" />
                        <span>Inspect Lineage</span>
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {/* Interactive Lineage Exposure Section */}
          {selectedRecall && (
            <div className="mt-6 pt-6 border-t border-slate-800/80 space-y-4">
              <div className="flex items-center justify-between">
                <div>
                  <h3 className="text-sm font-semibold text-blue-400 flex items-center gap-2">
                    <GitFork className="h-4 w-4" />
                    <span>Contamination Flow Graph: Batch {selectedRecall.batch_code} ({selectedRecall.product_name})</span>
                  </h3>
                  <p className="text-xs text-slate-400 mt-0.5">
                    Evaluates downstream stock exposure across warehouses, retailers, and end customers.
                  </p>
                </div>
                <button
                  onClick={() => setSelectedRecall(null)}
                  className="text-xs text-slate-400 hover:text-white px-2 py-1 rounded bg-slate-800"
                >
                  Close Graph
                </button>
              </div>

              {isTracing ? (
                <div className="p-8 text-center text-xs font-mono text-slate-400">Traversing relational nodes...</div>
              ) : (
                <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
                  {/* Stock Exposure Card */}
                  <div className="bg-[#080D1A] border border-slate-800 rounded-xl p-4">
                    <div className="flex items-center gap-2 text-xs font-semibold text-slate-300 uppercase tracking-wider mb-3">
                      <Warehouse className="h-4 w-4 text-amber-400" />
                      <span>Stock Exposure (Warehouses & Retailers)</span>
                    </div>

                    <div className="space-y-2">
                      {traceData?.stockExposure && traceData.stockExposure.length > 0 ? (
                        traceData.stockExposure.map((item, idx) => (
                          <div key={idx} className="flex items-center justify-between bg-slate-900/60 p-2.5 rounded-lg border border-slate-800/80 text-xs">
                            <div className="flex items-center gap-2">
                              {item.location_type === 'warehouse' ? (
                                <Building2 className="h-3.5 w-3.5 text-blue-400" />
                              ) : (
                                <Store className="h-3.5 w-3.5 text-emerald-400" />
                              )}
                              <div>
                                <div className="font-medium text-slate-200">{item.location_name}</div>
                                <div className="text-[10px] text-slate-500 uppercase font-mono">{item.location_type}</div>
                              </div>
                            </div>
                            <span className="font-mono font-bold text-amber-400 bg-amber-400/10 px-2 py-0.5 rounded border border-amber-400/20">
                              {item.quantity_on_hand} Units
                            </span>
                          </div>
                        ))
                      ) : (
                        <p className="text-xs text-slate-500 font-mono py-2">No inventory held in active facilities.</p>
                      )}
                    </div>
                  </div>

                  {/* Customer Impact Card */}
                  <div className="bg-[#080D1A] border border-slate-800 rounded-xl p-4">
                    <div className="flex items-center gap-2 text-xs font-semibold text-slate-300 uppercase tracking-wider mb-3">
                      <Users className="h-4 w-4 text-rose-400" />
                      <span>Downstream Affected Customers</span>
                    </div>

                    <div className="space-y-2">
                      {traceData?.customers && traceData.customers.length > 0 ? (
                        traceData.customers.map((c, idx) => (
                          <div key={idx} className="flex items-center justify-between bg-slate-900/60 p-2.5 rounded-lg border border-slate-800/80 text-xs">
                            <div>
                              <div className="font-medium text-slate-200">{c.customer}</div>
                              <div className="text-[10px] text-slate-400">{c.email || c.phone} • Via {c.retailer}</div>
                            </div>
                            <div className="text-right">
                              <span className="font-mono font-bold text-rose-400 bg-rose-400/10 px-2 py-0.5 rounded border border-rose-400/20">
                                {c.quantity} Units Sold
                              </span>
                            </div>
                          </div>
                        ))
                      ) : (
                        <p className="text-xs text-slate-500 font-mono py-2">No retail units sold to consumers.</p>
                      )}
                    </div>
                  </div>
                </div>
              )}
            </div>
          )}
        </section>

      </main>
    </div>
  );
}