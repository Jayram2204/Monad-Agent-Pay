'use client';

import { useState, useEffect } from 'react';

interface LogEntry {
  id: number;
  timestamp: string;
  resource: string;
  latency: string;
  cost: string;
  txHash: string;
  status: 'success' | 'pending' | 'failed';
  signature: string;
  paymentAmount?: string;
}

export function TerminalLogWidget() {
  const [logs, setLogs] = useState<LogEntry[]>([]);
  const [isVisible, setIsVisible] = useState(true);
  const [totalHandshakes, setTotalHandshakes] = useState(0);
  const [successfulPayments, setSuccessfulPayments] = useState(0);
  const [totalCost, setTotalCost] = useState(0);

  useEffect(() => {
    // Simulate x402 handshake logs with payment data
    const resources = [
      'api.openai.com/v1/chat/completions',
      'api.stripe.com/v1/charges',
      'api.coinbase.com/v2/prices',
      'api.github.com/repos',
      'api.twitter.com/2/tweets',
      'api.google.com/v1/search',
      'api.aws.amazon.com/s3',
      'api.cloudflare.com/dns'
    ];

    const generateLogEntry = (): LogEntry => {
      const resource = resources[Math.floor(Math.random() * resources.length)];
      const latency = (Math.random() * 1.5 + 0.3).toFixed(1) + 's';
      const cost = (Math.random() * 0.0008 + 0.0001).toFixed(6);
      const status = Math.random() > 0.08 ? 'success' : 'failed';
      const paymentAmount = status === 'success' ? (Math.random() * 0.005 + 0.001).toFixed(6) : undefined;
      
      return {
        id: Date.now() + Math.random(),
        timestamp: new Date().toLocaleTimeString(),
        resource: resource.split('/')[2] || resource,
        latency,
        cost,
        txHash: '0x' + Array(64).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
        signature: '0x' + Array(130).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join(''),
        status,
        paymentAmount
      };
    };

    // Initial logs
    const initialLogs = Array.from({ length: 6 }, () => generateLogEntry());
    setLogs(initialLogs);
    setTotalHandshakes(6);
    setSuccessfulPayments(initialLogs.filter(l => l.status === 'success').length);
    setTotalCost(initialLogs.reduce((sum, log) => sum + (log.paymentAmount ? parseFloat(log.paymentAmount) : 0), 0));

    // Add new logs periodically with varying intensity
    const interval = setInterval(() => {
      if (isVisible) {
        setLogs(prev => {
          const newLog = generateLogEntry();
          const updated = [newLog, ...prev];
          
          // Update counters
          setTotalHandshakes(prev => prev + 1);
          if (newLog.status === 'success') {
            setSuccessfulPayments(prev => prev + 1);
            if (newLog.paymentAmount) {
              setTotalCost(prev => prev + parseFloat(newLog.paymentAmount || "0"));
            }
          }
          
          return updated.slice(0, 25); // Keep only last 25 entries
        });
      }
    }, Math.random() * 1500 + 500); // Random interval 500-2000ms

    return () => clearInterval(interval);
  }, [isVisible]);

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'success': return '✅';
      case 'pending': return '⏳';
      case 'failed': return '❌';
      default: return '○';
    }
  };

  return (
    <div className="h-full flex flex-col">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-lg font-bold text-monad-purple">X402 HANDSHAKE LOG</h2>
        <div className="flex gap-2">
          <button 
            onClick={() => setIsVisible(!isVisible)}
            className="px-2 py-1 text-xs bg-monad-purple/20 text-monad-purple border border-monad-purple rounded hover:bg-monad-purple/30"
          >
            {isVisible ? 'PAUSE' : 'RESUME'}
          </button>
        </div>
      </div>
      
      <div className="flex-1 terminal-log">
        <div className="log-entry font-bold text-slate-400 border-b border-monad-purple/30">
          <div>STATUS</div>
          <div>RESOURCE</div>
          <div>LATENCY</div>
          <div>AMOUNT</div>
        </div>
        
        <div className="overflow-y-auto max-h-[300px]">
          {logs.map((log) => (
            <div 
              key={log.id} 
              className={`log-entry ${log.status === 'success' ? '' : 'opacity-60'}`}
            >
              <div className="font-mono text-sm">
                {getStatusIcon(log.status)}
              </div>
              <div className="font-mono text-sm truncate" title={log.resource}>
                {log.resource}
              </div>
              <div className={`font-mono text-sm ${parseFloat(log.latency) <= 0.8 ? 'highlight-pink' : 'text-slate-300'}`}>
                {log.latency}
              </div>
              <div className="font-mono text-sm text-slate-300">
                {log.paymentAmount ? `${log.paymentAmount} ETH` : '--'}
              </div>
            </div>
          ))}
        </div>
      </div>
      
      <div className="mt-4 grid grid-cols-3 gap-2 text-xs">
        <div className="text-center p-2 bg-black/30 border border-monad-purple/20 rounded">
          <div className="text-slate-400 mb-1">HANDSHAKES</div>
          <div className="text-neon-pink font-bold">{totalHandshakes}</div>
        </div>
        <div className="text-center p-2 bg-black/30 border border-monad-purple/20 rounded">
          <div className="text-slate-400 mb-1">SUCCESS</div>
          <div className="text-green-400 font-bold">{successfulPayments}</div>
        </div>
        <div className="text-center p-2 bg-black/30 border border-monad-purple/20 rounded">
          <div className="text-slate-400 mb-1">TOTAL COST</div>
          <div className="text-yellow-400 font-bold">{totalCost.toFixed(6)} ETH</div>
        </div>
      </div>
      
      <div className="mt-3 text-xs text-slate-500">
        <div className="flex justify-between">
          <span>MONAD FINALITY: <span className="text-neon-pink">0.8s</span></span>
          <span>VERIFICATION: <span className="text-green-400">ACTIVE</span></span>
        </div>
        <div className="flex justify-between mt-1">
          <span>LOG STATUS: <span className={isVisible ? "text-green-400" : "text-slate-500"}>
            {isVisible ? "LIVE" : "PAUSED"}</span></span>
          <span>SUCCESS RATE: <span className="text-green-400">
            {totalHandshakes > 0 ? ((successfulPayments / totalHandshakes) * 100).toFixed(1) : "0"}%
          </span></span>
        </div>
      </div>
    </div>
  );
}