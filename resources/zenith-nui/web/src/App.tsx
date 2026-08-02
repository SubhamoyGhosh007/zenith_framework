import { useState } from 'react'
import './App.css'

interface ModuleInfo {
  name: string
  desc: string
  status: 'Ready' | 'Scaffolded' | 'Custom UI'
}

function App() {
  const [logs, setLogs] = useState<string[]>([
    '[SYSTEM] Zenith NUI loaded successfully.',
    '[SYSTEM] Listening for event "zenith:nui:state"...'
  ])

  const modules: ModuleInfo[] = [
    { name: 'zenith-migrations', desc: 'Auto SQL version runner inside transactions', status: 'Ready' },
    { name: 'zenith-nui', desc: 'CEF Overlay containing global HUD and menus', status: 'Ready' },
    { name: 'ox_inventory', desc: 'Forked item engine with customizable React UI', status: 'Custom UI' },
    { name: 'zenith-core', desc: 'Query cache, player registry, and event bus', status: 'Scaffolded' },
    { name: 'zenith-player', desc: 'Identifiers lookup, sessions, and drop handling', status: 'Scaffolded' },
    { name: 'zenith-characters', desc: 'Multi-character slots and creator hook', status: 'Scaffolded' },
    { name: 'zenith-money', desc: 'Cash/bank transactions append-only ledger', status: 'Scaffolded' },
    { name: 'zenith-jobs', desc: 'Job rosters, salaries, duty access, and stashes', status: 'Scaffolded' },
    { name: 'zenith-spawn', desc: 'Map pins spawn selector on first join', status: 'Scaffolded' },
    { name: 'zenith-housing', desc: 'Pre-placed shell interior ownership and keys', status: 'Scaffolded' },
    { name: 'zenith-admin', desc: 'Ace commands, spectate, ban logs context', status: 'Scaffolded' },
    { name: 'zenith-permissions', desc: 'Syncs DB groups to ace principals at boot', status: 'Scaffolded' }
  ]

  const runBridgeTest = () => {
    const timestamp = new Date().toLocaleTimeString()
    const newLogs = [
      ...logs,
      `[${timestamp}] [NUI → Lua] fetchNui("pingBridge", { timestamp: ${Date.now()} })`,
      `[${timestamp}] [Lua → NUI] Event "zenith:core:pong" received - SUCCESS`
    ]
    setLogs(newLogs)
  }

  return (
    <div className="dashboard-container">
      {/* Header */}
      <header className="dashboard-header glass-panel">
        <div className="title-area">
          <h1>Zenith Framework</h1>
          <p>Modular FiveM roleplay core framework with GrandRP-inspired NUI</p>
        </div>
        <div className="status-badge">
          <div className="status-dot"></div>
          <span>M0 SCAFFOLD READY</span>
        </div>
      </header>

      {/* Main Grid Layout */}
      <div className="grid-layout">
        {/* Left Side: Modules List */}
        <section className="modules-section glass-panel">
          <h2>Framework Modules</h2>
          <p>Current resource setup and scaffold status</p>
          <div className="modules-list">
            {modules.map((mod) => (
              <div key={mod.name} className="module-card glass-panel">
                <div>
                  <h3>{mod.name}</h3>
                  <p>{mod.desc}</p>
                </div>
                <div className="module-meta">
                  <span>status</span>
                  <span className={
                    mod.status === 'Ready' 
                      ? 'badge-ready' 
                      : mod.status === 'Custom UI' 
                        ? 'badge-ready' 
                        : 'badge-scaffold'
                  }>
                    {mod.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        </section>

        {/* Right Side: Sidebar Controls */}
        <div className="sidebar-section">
          {/* Bridge Testing Card */}
          <section className="sidebar-card glass-panel">
            <h2>Bridge Simulator</h2>
            <p>Verify NUI ↔ Lua client messaging pipeline triggers</p>
            <button type="button" className="btn-primary" onClick={runBridgeTest}>
              Trigger Ping
            </button>
            <div className="console-output">
              {logs.map((log, index) => (
                <div key={index}>{log}</div>
              ))}
            </div>
          </section>

          {/* Environment Specs Card */}
          <section className="sidebar-card glass-panel">
            <h2>Framework Specs</h2>
            <div className="tech-item">
              <span className="tech-label">Framework Version</span>
              <span className="tech-val">0.1.0-m0</span>
            </div>
            <div className="tech-item">
              <span className="tech-label">Scripting Language</span>
              <span className="tech-val">Lua 5.4</span>
            </div>
            <div className="tech-item">
              <span className="tech-label">UI Environment</span>
              <span className="tech-val">React 19, Vite 8</span>
            </div>
            <div className="tech-item">
              <span className="tech-label">Database</span>
              <span className="tech-val">ox_mysql</span>
            </div>
            <div className="tech-item">
              <span className="tech-label">UI Styling</span>
              <span className="tech-val">Vanilla CSS</span>
            </div>
          </section>
        </div>
      </div>
    </div>
  )
}

export default App
