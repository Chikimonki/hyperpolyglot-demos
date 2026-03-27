import { useState, useEffect } from 'react'
import axios from 'axios'

const API_URL = 'https://go-gateway-x6vvbvhpsq-uc.a.run.app'

function App() {
  const [health, setHealth] = useState(null)
  const [fibN, setFibN] = useState(20)
  const [fibResult, setFibResult] = useState(null)
  const [primeRange, setPrimeRange] = useState({ start: 1, end: 100 })
  const [primeResult, setPrimeResult] = useState(null)
  const [loading, setLoading] = useState({})

  useEffect(() => {
    checkHealth()
  }, [])

  const checkHealth = async () => {
    try {
      const { data } = await axios.get(`${API_URL}/health`)
      setHealth(data)
    } catch (error) {
      console.error('Health check failed:', error)
    }
  }

  const calculateFibonacci = async () => {
    setLoading(prev => ({ ...prev, fib: true }))
    try {
      const { data } = await axios.get(`${API_URL}/api/fibonacci/${fibN}`)
      setFibResult(data)
    } catch (error) {
      console.error('Fibonacci failed:', error)
    }
    setLoading(prev => ({ ...prev, fib: false }))
  }

  const findPrimes = async () => {
    setLoading(prev => ({ ...prev, primes: true }))
    try {
      const { data } = await axios.post(`${API_URL}/api/primes`, primeRange)
      setPrimeResult(data)
    } catch (error) {
      console.error('Primes failed:', error)
    }
    setLoading(prev => ({ ...prev, primes: false }))
  }

  return (
    <div>
      <div className="header">
        <div className="container">
          <h1 className="main-title">🚀 Hyperpolyglot Stack</h1>
          <p className="tagline">
            Production polyglot microservices: Zig • Python • Go • Julia • LuaJIT
          </p>
        </div>
      </div>

      <div className="container">
        <div className="card">
          <h2>⚡ Service Health</h2>
          {health ? (
            <div className="badge-grid">
              <div className="badge">
                <div className={`status-dot ${health.backends?.python?.healthy ? 'healthy' : 'unhealthy'}`}></div>
                <span>Python + Zig</span>
                <span>{health.backends?.python?.healthy ? '✓' : '✗'}</span>
              </div>
              <div className="badge">
                <div className={`status-dot ${health.backends?.julia?.healthy ? 'healthy' : 'unhealthy'}`}></div>
                <span>Julia Analytics</span>
                <span>{health.backends?.julia?.healthy ? '✓' : '✗'}</span>
              </div>
              <div className="badge">
                <div className={`status-dot ${health.backends?.lua?.healthy ? 'healthy' : 'unhealthy'}`}></div>
                <span>LuaJIT Scripting</span>
                <span>{health.backends?.lua?.healthy ? '✓' : '✗'}</span>
              </div>
            </div>
          ) : (
            <p>Checking services...</p>
          )}
        </div>

        <div className="card">
          <h2>🔢 Fibonacci Calculator <small>(Python → Zig)</small></h2>
          <div className="input-group">
            <input
              type="number"
              value={fibN}
              onChange={(e) => setFibN(e.target.value)}
              placeholder="Enter n"
            />
            <button onClick={calculateFibonacci} disabled={loading.fib}>
              {loading.fib ? 'Computing...' : 'Calculate'}
            </button>
          </div>
          {fibResult && (
            <div className="result">
              fibonacci({fibResult.n}) = {fibResult.result?.toLocaleString()}
            </div>
          )}
        </div>

        <div className="card">
          <h2>🔍 Prime Number Finder <small>(Python → Zig)</small></h2>
          <div className="input-group">
            <input
              type="number"
              value={primeRange.start}
              onChange={(e) => setPrimeRange({ ...primeRange, start: parseInt(e.target.value) })}
              placeholder="Start"
            />
            <input
              type="number"
              value={primeRange.end}
              onChange={(e) => setPrimeRange({ ...primeRange, end: parseInt(e.target.value) })}
              placeholder="End"
            />
          </div>
          <button onClick={findPrimes} disabled={loading.primes}>
            {loading.primes ? 'Finding...' : 'Find Primes'}
          </button>
          {primeResult && (
            <div>
              <div className="result">
                Found {primeResult.count} primes
              </div>
              <div className="prime-list">
                {primeResult.primes?.slice(0, 100).map((p, i) => (
                  <span key={i} className="prime-number">{p}</span>
                ))}
                {primeResult.primes?.length > 100 && <span>...</span>}
              </div>
            </div>
          )}
        </div>

        <div className="footer">
          <p>Built with Zig • Python • Go • Julia • LuaJIT</p>
          <p>Deployed on GCP Cloud Run</p>
        </div>
      </div>
    </div>
  )
}

export default App
