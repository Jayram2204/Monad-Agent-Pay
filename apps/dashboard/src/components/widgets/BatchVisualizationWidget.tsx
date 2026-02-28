'use client';

import { useState, useEffect } from 'react';

interface MicroPayment {
  id: number;
  amount: string;
  recipient: string;
  status: 'pending' | 'bundled' | 'processed';
}

export function BatchVisualizationWidget() {
  const [microPayments, setMicroPayments] = useState<MicroPayment[]>([]);
  const [bundledCount, setBundledCount] = useState(0);
  const [totalSaved, setTotalSaved] = useState(0);

  useEffect(() => {
    // Initialize 10 micro-payments
    const initialPayments: MicroPayment[] = Array.from({ length: 10 }, (_, i) => ({
      id: i + 1,
      amount: `${(Math.random() * 0.001 + 0.0001).toFixed(6)} ETH`,
      recipient: `0x${Array(40).fill(0).map(() => Math.floor(Math.random() * 16).toString(16)).join('')}`,
      status: 'pending'
    }));
    
    setMicroPayments(initialPayments);
    
    // Simulate bundling process
    const bundleInterval = setInterval(() => {
      setMicroPayments(prev => {
        const updated = [...prev];
        let bundled = 0;
        
        // Randomly bundle some payments
        updated.forEach(payment => {
          if (payment.status === 'pending' && Math.random() > 0.7) {
            payment.status = 'bundled';
            bundled++;
          }
        });
        
        setBundledCount(prev => prev + bundled);
        setTotalSaved(prev => prev + (bundled * 0.00005)); // 0.00005 ETH saved per bundled payment
        
        return updated;
      });
    }, 3000);

    // Process bundled payments
    const processInterval = setInterval(() => {
      setMicroPayments(prev => {
        const updated = [...prev];
        let processed = 0;
        
        updated.forEach(payment => {
          if (payment.status === 'bundled' && Math.random() > 0.8) {
            payment.status = 'processed';
            processed++;
          }
        });
        
        return updated;
      });
    }, 5000);

    return () => {
      clearInterval(bundleInterval);
      clearInterval(processInterval);
    };
  }, []);

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'pending': return 'text-yellow-400';
      case 'bundled': return 'text-neon-pink';
      case 'processed': return 'text-green-400';
      default: return 'text-slate-400';
    }
  };

  const getStatusIcon = (status: string) => {
    switch (status) {
      case 'pending': return '⏳';
      case 'bundled': return '📦';
      case 'processed': return '✅';
      default: return '○';
    }
  };

  return (
    <div className="h-full flex flex-col">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-lg font-bold text-monad-purple">BATCH VISUALIZATION</h2>
        <div className="flex gap-4 text-sm">
          <div className="text-slate-400">
            BUNDLED: <span className="text-neon-pink font-bold">{bundledCount}/10</span>
          </div>
          <div className="text-slate-400">
            SAVED: <span className="text-green-400 font-bold">{totalSaved.toFixed(6)} ETH</span>
          </div>
          <div className="text-slate-400">
            FEE REDUCTION: <span className="text-neon-pink font-bold">90%</span>
          </div>
        </div>
      </div>

      <div className="flex-1">
        <div className="grid grid-cols-10 gap-2 mb-4">
          {microPayments.map((payment) => (
            <div 
              key={payment.id}
              className={`p-2 border rounded text-center text-xs transition-all duration-300 ${
                payment.status === 'pending' 
                  ? 'border-yellow-400/30 bg-yellow-400/10' 
                  : payment.status === 'bundled' 
                    ? 'border-neon-pink/50 bg-neon-pink/20 scale-110' 
                    : 'border-green-400/30 bg-green-400/10'
              }`}
            >
              <div className="mb-1">{getStatusIcon(payment.status)}</div>
              <div className={`font-bold ${getStatusColor(payment.status)}`}>
                {payment.status.toUpperCase()}
              </div>
              <div className="text-slate-400 mt-1 text-[0.6rem]">
                {payment.amount}
              </div>
            </div>
          ))}
        </div>

        <div className="bg-black/30 border border-monad-purple/30 rounded p-4">
          <h3 className="text-sm font-bold text-slate-300 mb-3">BATCH PROCESSING PIPELINE</h3>
          
          <div className="grid grid-cols-4 gap-4">
            <div className="text-center">
              <div className="text-2xl mb-1">💰</div>
              <div className="text-xs text-slate-400 mb-1">INDIVIDUAL</div>
              <div className="text-sm font-bold text-yellow-400">10 PAYMENTS</div>
              <div className="text-xs text-slate-500">0.00842 ETH</div>
            </div>
            
            <div className="text-center">
              <div className="text-2xl mb-1">→</div>
              <div className="text-xs text-slate-400 mb-1">BUNDLING</div>
              <div className="text-sm font-bold text-neon-pink">CALLTYPE_BATCH</div>
              <div className="text-xs text-slate-500">1 TRANSACTION</div>
            </div>
            
            <div className="text-center">
              <div className="text-2xl mb-1">→</div>
              <div className="text-xs text-slate-400 mb-1">EXECUTION</div>
              <div className="text-sm font-bold text-green-400">MONAD SETTLEMENT</div>
              <div className="text-xs text-slate-500">0.00084 ETH</div>
            </div>
            
            <div className="text-center">
              <div className="text-2xl mb-1">🎉</div>
              <div className="text-xs text-slate-400 mb-1">SAVINGS</div>
              <div className="text-sm font-bold text-green-400">90% REDUCTION</div>
              <div className="text-xs text-slate-500">0.00758 ETH SAVED</div>
            </div>
          </div>
        </div>
      </div>

      <div className="mt-4 grid grid-cols-3 gap-4 text-xs">
        <div className="text-center p-2 border border-monad-purple/20 rounded">
          <div className="text-slate-400 mb-1">BLOCK TIME</div>
          <div className="text-neon-pink font-bold">400ms</div>
        </div>
        <div className="text-center p-2 border border-monad-purple/20 rounded">
          <div className="text-slate-400 mb-1">SETTLEMENT</div>
          <div className="text-neon-pink font-bold">800ms</div>
        </div>
        <div className="text-center p-2 border border-monad-purple/20 rounded">
          <div className="text-slate-400 mb-1">THROUGHPUT</div>
          <div className="text-green-400 font-bold">1000 TPS</div>
        </div>
      </div>
    </div>
  );
}