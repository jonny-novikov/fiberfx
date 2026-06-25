#!/usr/bin/env node
/**
 * Kill processes on mini-app ports 3041-3042 (cross-platform)
 */

import { execSync } from 'child_process'

const PORTS = [4200, 4201, 4202]
const isWindows = process.platform === 'win32'

for (const port of PORTS) {
  try {
    if (isWindows) {
      // Windows: find PID and kill
      const result = execSync(`netstat -ano | findstr :${port} | findstr LISTENING`, {
        encoding: 'utf-8',
      })
      const lines = result.trim().split('\n')
      for (const line of lines) {
        const parts = line.trim().split(/\s+/)
        const pid = parts[parts.length - 1]
        if (pid && !isNaN(pid)) {
          try {
            execSync(`taskkill /F /PID ${pid}`, { stdio: 'inherit' })
            console.log(`Killed process ${pid} on port ${port}`)
          } catch (e) {
            console.log(`Error killing process ${pid} on port ${port}`, e)
            // Process may have already exited
          }
        }
      }
    } else {
      // Unix: use lsof
      execSync(`lsof -ti:${port} | xargs kill -9 2>/dev/null || true`, { stdio: 'inherit' })
      console.log(`Killed processes on port ${port}`)
    }
  } catch (e) {
    console.log(`No process found on port ${port}`, e)
  }
}

console.log('Done')
