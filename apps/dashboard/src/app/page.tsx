import { SavingsDeltaWidget } from "@/components/widgets/SavingsDeltaWidget";
import { AccountBalanceWidget } from "@/components/widgets/AccountBalanceWidget";
import { TerminalLogWidget } from "@/components/widgets/TerminalLogWidget";
import { ControlPanelWidget } from "@/components/widgets/ControlPanelWidget";
import { BatchVisualizationWidget } from "@/components/widgets/BatchVisualizationWidget";
import { NetworkStats } from "@/components/NetworkStats";

export default function Dashboard() {
  return (
    <div className="min-h-screen bg-black text-slate-100">
      {/* Header */}
      <header className="border-b border-monad-purple p-4">
        <div className="flex items-center justify-between">
          <h1 className="text-2xl font-bold text-monad-purple">AGENTPAY</h1>
          <NetworkStats />
        </div>
      </header>

      {/* Main Dashboard */}
      <main className="p-6">
        <div className="grid grid-cols-4 gap-4">
          {/* Widget 1: Savings Delta */}
          <div className="col-span-2 row-span-2 border border-monad-purple bg-black/80 p-4">
            <SavingsDeltaWidget />
          </div>

          {/* Widget 2: Account Balance */}
          <div className="col-span-2 border border-monad-purple bg-black/80 p-4">
            <AccountBalanceWidget />
          </div>

          {/* Widget 3: Terminal Log */}
          <div className="col-span-2 row-span-2 border border-monad-purple bg-black/80 p-4">
            <TerminalLogWidget />
          </div>

          {/* Widget 4: Control Panel */}
          <div className="col-span-2 border border-monad-purple bg-black/80 p-4">
            <ControlPanelWidget />
          </div>

          {/* Widget 5: Batch Visualization */}
          <div className="col-span-4 border border-monad-purple bg-black/80 p-4">
            <BatchVisualizationWidget />
          </div>
        </div>
      </main>
    </div>
  );
}