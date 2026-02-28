'use client';

import { useState, useEffect } from 'react';

export function SavingsDeltaWidget() {
  const [originalAmount, setOriginalAmount] = useState(50.00);
  const [currentAmount, setCurrentAmount] = useState(50.00);
  const [isAnimating, setIsAnimating] = useState(false);
  const [transactionsProcessed, setTransactionsProcessed] = useState(0);
  const [totalSavings, setTotalSavings] = useState(0);
  const [gasSaved, setGasSaved] = useState(0);

  useEffect(() => {
    // Simulate real transaction processing
    const processingInterval = setInterval(() => {
      if (isAnimating && currentAmount > 2.10) {
        const reduction = Math.random() * 0.5 + 0.1;
        const newAmount = Math.max(2.10, currentAmount - reduction);
        setCurrentAmount(newAmount);
        
        if (newAmount < currentAmount) {
          setTransactionsProcessed(prev => prev + 1);
          setTotalSavings(prev => prev + (currentAmount - newAmount));
          setGasSaved(prev => prev + (Math.random() * 15000 + 5000));
        }
      }
    }, 150);

    // Simulate batch processing events
    const batchInterval = setInterval(() => {
      if (isAnimating && Math.random() > 0.7) {
        // Simulate a batch of 5-10 transactions being optimized
        const batchSize = Math.floor(Math.random() * 6) + 5;
        setTransactionsProcessed(prev => prev + batchSize);
      }
    }, 3000);

    return () => {
      clearInterval(processingInterval);
      clearInterval(batchInterval);
    };
  }, [currentAmount, isAnimating]);

  const startAnimation = () => {
    setIsAnimating(true);
    setOriginalAmount(50.00);
    setCurrentAmount(50.00);
    setTransactionsProcessed(0);
    setTotalSavings(0);
    setGasSaved(0);
  };

  const formatGas = (gas: number) => {
    if (gas > 1000000) return `${(gas / 1000000).toFixed(1)}M gas`;
    if (gas > 1000) return `${(gas / 1000).toFixed(1)}K gas`;
    return `${gas.toFixed(0)} gas`;
  };

  return (
    <div className="h-full flex flex-col">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-lg font-bold text-monad-purple">SAVINGS DELTA</h2>
        <button 
          onClick={startAnimation}
          className="px-3 py-1 bg-monad-purple/20 text-monad-purple border border-monad-purple rounded text-sm hover:bg-monad-purple/30 transition-colors"
        >
          {isAnimating ? 'RESTART' : 'START OPTIMIZATION'}
        </button>
      </div>
      
      <div className="flex-1 flex flex-col items-center justify-center">
        <div className="text-center mb-6">
          <div className="savings-delta mb-2">96% SAVED</div>
          <div className="text-sm text-slate-400">AUTONOMOUS COST OPTIMIZATION</div>
        </div>
        
        <div className="text-center mb-6">
          <div className="text-sm text-slate-400 mb-2">ORIGINAL vs OPTIMIZED</div>
          <div className="flex items-center gap-4">
            <div className="text-slate-400 line-through">
              ${originalAmount.toFixed(2)}
            </div>
            <div className="text-2xl font-bold text-neon-pink">
              → ${currentAmount.toFixed(2)}
            </div>
          </div>
          <div className="text-xs text-slate-500 mt-2">
            SAVINGS: ${(originalAmount - currentAmount).toFixed(2)}
          </div>
        </div>

        <div className="grid grid-cols-3 gap-4 text-center w-full">
          <div className="p-2 bg-black/30 border border-monad-purple/20 rounded">
            <div className="text-neon-pink font-bold text-lg">{transactionsProcessed}</div>
            <div className="text-xs text-slate-400">TX PROCESSED</div>
          </div>
          <div className="p-2 bg-black/30 border border-monad-purple/20 rounded">
            <div className="text-green-400 font-bold text-lg">{formatGas(gasSaved)}</div>
            <div className="text-xs text-slate-400">GAS SAVED</div>
          </div>
          <div className="p-2 bg-black/30 border border-monad-purple/20 rounded">
            <div className="text-yellow-400 font-bold text-lg">${totalSavings.toFixed(2)}</div>
            <div className="text-xs text-slate-400">TOTAL SAVINGS</div>
          </div>
        </div>
      </div>
      
      <div className="mt-4 text-xs text-slate-500">
        <div className="flex justify-between">
          <span>AGENT STATUS: <span className="text-green-400">ACTIVE</span></span>
          <span>OPTIMIZATION: <span className="text-neon-pink">96%</span></span>
        </div>
        <div className="flex justify-between mt-1">
          <span>PROCESSING: <span className={isAnimating ? "text-green-400" : "text-slate-500"}>
            {isAnimating ? "RUNNING" : "IDLE"}</span></span>
          <span>EFFICIENCY: <span className="text-green-400">MAX</span></span>
        </div>
      </div>
    </div>
  );
}