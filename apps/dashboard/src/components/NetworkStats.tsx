'use client';

import { useState, useEffect } from 'react';

export function NetworkStats() {
  const [blockTime, setBlockTime] = useState(400);
  const [settlementTime, setSettlementTime] = useState(800);
  const [isConnected, setIsConnected] = useState(true);

  useEffect(() => {
    // Simulate network stats updates
    const interval = setInterval(() => {
      setBlockTime(400 + Math.floor(Math.random() * 20) - 10);
      setSettlementTime(800 + Math.floor(Math.random() * 40) - 20);
    }, 3000);

    return () => clearInterval(interval);
  }, []);

  return (
    <div className="flex items-center gap-4 text-sm">
      <div className="flex items-center gap-2">
        <div className={`w-2 h-2 rounded-full ${isConnected ? 'bg-green-400' : 'bg-red-400'}`}></div>
        <span className={isConnected ? 'text-green-400' : 'text-red-400'}>
          {isConnected ? 'CONNECTED' : 'DISCONNECTED'}
        </span>
      </div>
      
      <div className="flex items-center gap-2">
        <span className="text-slate-400">BLOCK:</span>
        <span className="text-neon-pink font-mono">{blockTime}ms</span>
      </div>
      
      <div className="flex items-center gap-2">
        <span className="text-slate-400">SETTLE:</span>
        <span className="text-neon-pink font-mono">{settlementTime}ms</span>
      </div>
      
      <div className="px-2 py-1 bg-monad-purple/20 text-monad-purple border border-monad-purple rounded text-xs">
        MONAD TESTNET
      </div>
    </div>
  );
}