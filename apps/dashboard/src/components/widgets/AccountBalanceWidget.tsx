'use client';

import { useState, useEffect } from 'react';

export function AccountBalanceWidget() {
  const [balance, setBalance] = useState(1.25); // 1.25 ETH
  const [spendLimit, setSpendLimit] = useState(0.5); // 0.5 ETH
  const [dailySpent, setDailySpent] = useState(0.15); // 0.15 ETH spent
  const [progress, setProgress] = useState(30); // 30% of daily limit used

  useEffect(() => {
    // Simulate balance updates
    const interval = setInterval(() => {
      setBalance(prev => Math.max(0, prev - (Math.random() * 0.001)));
      setDailySpent(prev => Math.min(spendLimit, prev + (Math.random() * 0.005)));
      
      const newProgress = (dailySpent * 100) / spendLimit;
      setProgress(Math.min(100, newProgress));
    }, 5000);

    return () => clearInterval(interval);
  }, [dailySpent, spendLimit]);

  const formatBalance = (eth: number) => {
    return eth.toFixed(4);
  };

  return (
    <div className="h-full flex flex-col">
      <h2 className="text-lg font-bold text-monad-purple mb-4">ACCOUNT BALANCE</h2>
      
      <div className="flex-1">
        <div className="mb-6">
          <div className="text-sm text-slate-400 mb-1">AGENT ACCOUNT BALANCE</div>
          <div className="text-2xl font-bold text-slate-100">
            {formatBalance(balance)} <span className="text-sm text-slate-500">ETH</span>
          </div>
        </div>

        <div className="mb-6">
          <div className="flex justify-between items-center mb-2">
            <span className="text-sm text-slate-400">DAILY SPENDING LIMIT</span>
            <span className="text-sm text-slate-300">
              {formatBalance(dailySpent)} / {formatBalance(spendLimit)} ETH
            </span>
          </div>
          <div className="progress-bar">
            <div 
              className="progress-fill" 
              style={{ width: `${progress}%` }}
            />
          </div>
          <div className="text-xs text-slate-500 mt-1">
            {progress}% of daily limit used
          </div>
        </div>

        <div className="grid grid-cols-2 gap-4 text-sm">
          <div>
            <div className="text-slate-400 mb-1">CONTRACT</div>
            <div className="text-slate-200 font-mono text-xs">
              0x742d...3f9a
            </div>
          </div>
          <div>
            <div className="text-slate-400 mb-1">NETWORK</div>
            <div className="text-slate-200">Monad Testnet</div>
          </div>
        </div>
      </div>

      <div className="mt-4 text-xs text-slate-500">
        <div>POLICY ENGINE: ACTIVE</div>
        <div className="text-neon-pink">LIMIT ENFORCEMENT: ENABLED</div>
      </div>
    </div>
  );
}