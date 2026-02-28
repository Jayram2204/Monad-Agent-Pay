'use client';

import { useState, useEffect } from 'react';

interface WhitelistedAPI {
  id: string;
  name: string;
  url: string;
  maxBudget: string;
  currentUsage: string;
  expiry: string;
  status: 'active' | 'pending' | 'expired' | 'near-limit';
  verificationBadge: boolean;
  lastAccess: string;
}

export function ControlPanelWidget() {
  const [whitelistedAPIs, setWhitelistedAPIs] = useState<WhitelistedAPI[]>([
    {
      id: '1',
      name: 'OpenAI API',
      url: 'api.openai.com',
      maxBudget: '0.05 ETH',
      currentUsage: '0.023 ETH',
      expiry: '2024-12-31',
      status: 'active',
      verificationBadge: true,
      lastAccess: '2 min ago'
    },
    {
      id: '2',
      name: 'Stripe API',
      url: 'api.stripe.com',
      maxBudget: '0.1 ETH',
      currentUsage: '0.089 ETH',
      expiry: '2024-11-15',
      status: 'near-limit',
      verificationBadge: true,
      lastAccess: '5 min ago'
    },
    {
      id: '3',
      name: 'Coinbase API',
      url: 'api.coinbase.com',
      maxBudget: '0.03 ETH',
      currentUsage: '0.012 ETH',
      expiry: '2024-10-20',
      status: 'active',
      verificationBadge: true,
      lastAccess: '1 hour ago'
    }
  ]);

  const [newAPI, setNewAPI] = useState({
    name: '',
    url: '',
    maxBudget: '0.01',
    expiry: ''
  });

  const [showAddForm, setShowAddForm] = useState(false);
  const [totalWhitelisted, setTotalWhitelisted] = useState(3);
  const [activeSessions, setActiveSessions] = useState(2);
  const [verifiedIntents, setVerifiedIntents] = useState(15);

  useEffect(() => {
    // Simulate API usage updates
    const interval = setInterval(() => {
      setWhitelistedAPIs(prev => {
        return prev.map(api => {
          if (api.status === 'active' && Math.random() > 0.7) {
            // Simulate usage increase
            const currentEth = parseFloat(api.currentUsage);
            const maxEth = parseFloat(api.maxBudget);
            const increment = Math.random() * 0.002;
            const newUsage = Math.min(maxEth * 0.95, currentEth + increment);
            
            let newStatus: WhitelistedAPI['status'] = api.status;
            if (newUsage > maxEth * 0.9) {
              newStatus = 'near-limit';
            }
            
            return {
              ...api,
              currentUsage: `${newUsage.toFixed(3)} ETH`,
              status: newStatus,
              lastAccess: 'Just now'
            };
          }
          return api;
        });
      });

      // Update counters
      if (Math.random() > 0.8) {
        setVerifiedIntents(prev => prev + 1);
      }
      if (Math.random() > 0.9) {
        setActiveSessions(prev => Math.min(5, prev + 1));
      }
    }, 3000);

    return () => clearInterval(interval);
  }, []);

  const addAPI = () => {
    if (newAPI.name && newAPI.url) {
      const newEntry: WhitelistedAPI = {
        id: Date.now().toString(),
        name: newAPI.name,
        url: newAPI.url,
        maxBudget: `${newAPI.maxBudget} ETH`,
        currentUsage: '0.000 ETH',
        expiry: newAPI.expiry || '2024-12-31',
        status: 'pending',
        verificationBadge: false,
        lastAccess: 'Never'
      };
      
      setWhitelistedAPIs([...whitelistedAPIs, newEntry]);
      setTotalWhitelisted(prev => prev + 1);
      setNewAPI({ name: '', url: '', maxBudget: '0.01', expiry: '' });
      setShowAddForm(false);
    }
  };

  const removeAPI = (id: string) => {
    setWhitelistedAPIs(whitelistedAPIs.filter(api => api.id !== id));
    setTotalWhitelisted(prev => Math.max(0, prev - 1));
  };

  const toggleVerification = (id: string) => {
    setWhitelistedAPIs(prev => 
      prev.map(api => 
        api.id === id 
          ? { ...api, verificationBadge: !api.verificationBadge }
          : api
      )
    );
  };

  const getStatusColor = (status: string) => {
    switch (status) {
      case 'active': return 'text-green-400';
      case 'pending': return 'text-yellow-400';
      case 'expired': return 'text-red-400';
      case 'near-limit': return 'text-orange-400';
      default: return 'text-slate-400';
    }
  };

  const getUsagePercentage = (current: string, max: string) => {
    const currentNum = parseFloat(current);
    const maxNum = parseFloat(max);
    return Math.min(100, (currentNum / maxNum) * 100);
  };

  return (
    <div className="h-full flex flex-col">
      <div className="flex justify-between items-center mb-4">
        <h2 className="text-lg font-bold text-monad-purple">CONTROL PANEL</h2>
        <button 
          onClick={() => setShowAddForm(!showAddForm)}
          className="px-3 py-1 bg-monad-purple/20 text-monad-purple border border-monad-purple rounded text-sm hover:bg-monad-purple/30 transition-colors"
        >
          {showAddForm ? 'CANCEL' : 'ADD API'}
        </button>
      </div>

      <div className="grid grid-cols-3 gap-2 mb-4">
        <div className="text-center p-2 bg-black/30 border border-monad-purple/20 rounded">
          <div className="text-slate-400 text-xs mb-1">WHITELISTED</div>
          <div className="text-neon-pink font-bold text-lg">{totalWhitelisted}</div>
        </div>
        <div className="text-center p-2 bg-black/30 border border-monad-purple/20 rounded">
          <div className="text-slate-400 text-xs mb-1">ACTIVE</div>
          <div className="text-green-400 font-bold text-lg">{activeSessions}</div>
        </div>
        <div className="text-center p-2 bg-black/30 border border-monad-purple/20 rounded">
          <div className="text-slate-400 text-xs mb-1">VERIFIED</div>
          <div className="text-yellow-400 font-bold text-lg">{verifiedIntents}</div>
        </div>
      </div>

      {showAddForm && (
        <div className="mb-4 p-3 border border-monad-purple/30 rounded bg-black/50">
          <h3 className="text-sm font-bold text-monad-purple mb-2">ADD NEW API</h3>
          <div className="grid grid-cols-2 gap-2 mb-3">
            <div>
              <label className="block text-xs text-slate-400 mb-1">API Name</label>
              <input
                type="text"
                value={newAPI.name}
                onChange={(e) => setNewAPI({...newAPI, name: e.target.value})}
                className="w-full px-2 py-1 bg-black/50 border border-monad-purple/30 rounded text-sm text-slate-100"
                placeholder="e.g., OpenAI API"
              />
            </div>
            <div>
              <label className="block text-xs text-slate-400 mb-1">API URL</label>
              <input
                type="text"
                value={newAPI.url}
                onChange={(e) => setNewAPI({...newAPI, url: e.target.value})}
                className="w-full px-2 py-1 bg-black/50 border border-monad-purple/30 rounded text-sm text-slate-100"
                placeholder="e.g., api.openai.com"
              />
            </div>
            <div>
              <label className="block text-xs text-slate-400 mb-1">Max Budget (ETH)</label>
              <input
                type="number"
                step="0.001"
                value={newAPI.maxBudget}
                onChange={(e) => setNewAPI({...newAPI, maxBudget: e.target.value})}
                className="w-full px-2 py-1 bg-black/50 border border-monad-purple/30 rounded text-sm text-slate-100"
              />
            </div>
            <div>
              <label className="block text-xs text-slate-400 mb-1">Expiry Date</label>
              <input
                type="date"
                value={newAPI.expiry}
                onChange={(e) => setNewAPI({...newAPI, expiry: e.target.value})}
                className="w-full px-2 py-1 bg-black/50 border border-monad-purple/30 rounded text-sm text-slate-100"
              />
            </div>
          </div>
          <button
            onClick={addAPI}
            className="px-3 py-1 bg-neon-pink text-black text-sm rounded font-bold hover:bg-pink-500 transition-colors"
          >
            WHITELIST API
          </button>
        </div>
      )}

      <div className="flex-1">
        <h3 className="text-sm font-bold text-slate-300 mb-3">AP2 INTENT MANDATES</h3>
        
        <div className="space-y-3 max-h-60 overflow-y-auto">
          {whitelistedAPIs.map((api) => (
            <div 
              key={api.id} 
              className="p-3 border border-monad-purple/20 rounded bg-black/30"
            >
              <div className="flex justify-between items-start mb-2">
                <div className="flex items-center gap-2">
                  <span className="font-bold text-slate-100">{api.name}</span>
                  <span className={`text-xs px-2 py-0.5 rounded ${getStatusColor(api.status)}`}>
                    {api.status.toUpperCase()}
                  </span>
                  {api.verificationBadge && (
                    <span className="text-xs px-2 py-0.5 bg-green-500/20 text-green-400 border border-green-500/30 rounded">
                      VERIFIED
                    </span>
                  )}
                </div>
                <button
                  onClick={() => toggleVerification(api.id)}
                  className={`px-2 py-1 text-xs ${api.verificationBadge ? 'bg-green-500/20 text-green-400 border-green-500/30' : 'bg-slate-500/20 text-slate-400 border-slate-500/30'} rounded hover:opacity-80`}
                >
                  {api.verificationBadge ? '✓' : '○'}
                </button>
              </div>
              
              <div className="text-xs text-slate-400 font-mono mb-2">
                {api.url}
              </div>
              
              <div className="mb-2">
                <div className="flex justify-between text-xs mb-1">
                  <span className="text-slate-400">USAGE</span>
                  <span className="text-slate-300">{api.currentUsage} / {api.maxBudget}</span>
                </div>
                <div className="progress-bar h-1.5">
                  <div 
                    className="progress-fill"
                    style={{ width: `${getUsagePercentage(api.currentUsage, api.maxBudget)}%` }}
                  />
                </div>
              </div>
              
              <div className="grid grid-cols-2 gap-4 text-xs">
                <div>
                  <span className="text-slate-500">EXPIRY:</span>
                  <span className="text-slate-300 ml-1">{api.expiry}</span>
                </div>
                <div>
                  <span className="text-slate-500">LAST:</span>
                  <span className="text-slate-300 ml-1">{api.lastAccess}</span>
                </div>
              </div>
              
              <div className="flex justify-end mt-2">
                <button
                  onClick={() => removeAPI(api.id)}
                  className="px-2 py-1 text-xs bg-red-500/20 text-red-400 border border-red-500/30 rounded hover:bg-red-500/30"
                >
                  REMOVE
                </button>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="mt-4 text-xs text-slate-500">
        <div className="flex justify-between">
          <span>AP2 INTENT MANDATE: <span className="text-neon-pink">ACTIVE</span></span>
          <span>WHITELIST STATUS: <span className="text-green-400">SECURE</span></span>
        </div>
        <div className="flex justify-between mt-1">
          <span>VERIFICATION: <span className="text-green-400">COMPLETED</span></span>
          <span>POLICY ENFORCEMENT: <span className="text-green-400">ENABLED</span></span>
        </div>
      </div>
    </div>
  );
}