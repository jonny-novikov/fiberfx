package main

import (
	"fmt"
	"os"
	"path/filepath"
	"strconv"
	"strings"
	"time"

	tea "github.com/charmbracelet/bubbletea"
	"github.com/charmbracelet/lipgloss"
)

// --- styles ------------------------------------------------------------------

var (
	titleStyle = lipgloss.NewStyle().Bold(true).
			Foreground(lipgloss.Color("231")).Background(lipgloss.Color("63")).Padding(0, 1)
	headerStyle   = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("244"))
	selStyle      = lipgloss.NewStyle().Bold(true).Foreground(lipgloss.Color("231"))
	dimStyle      = lipgloss.NewStyle().Foreground(lipgloss.Color("244"))
	msgStyle      = lipgloss.NewStyle().Foreground(lipgloss.Color("80"))
	runningStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("42"))
	startingStyle = lipgloss.NewStyle().Foreground(lipgloss.Color("214"))
	foreignStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("203"))
	stoppedStyle  = lipgloss.NewStyle().Foreground(lipgloss.Color("240"))
	docStyle      = lipgloss.NewStyle().Padding(1, 2)
)

// --- model -------------------------------------------------------------------

type srvState struct {
	srv       Server
	pid       int
	live      bool
	listening bool
}

type tuiModel struct {
	root     string
	rows     []srvState
	cursor   int
	message  string
	busy     bool
	quitting bool
}

type (
	tickMsg       time.Time
	probedMsg     []srvState
	actionDoneMsg string
)

// runTUI validates the root and runs the control panel. The TUI manages servers
// DETACHED (every action uses the -d path), so quitting the panel leaves them
// running — it's a control surface, not their parent.
func runTUI(root string) error {
	if _, err := os.Stat(filepath.Join(root, ".mcp.json")); err != nil {
		return fmt.Errorf("no .mcp.json at repo root %s — aaw's strict wire-check requires it", root)
	}
	if err := os.MkdirAll(binDir(root), 0o755); err != nil {
		return err
	}
	m := tuiModel{root: root, rows: probeAll(root)}
	_, err := tea.NewProgram(m, tea.WithAltScreen()).Run()
	return err
}

func (m tuiModel) Init() tea.Cmd {
	return tea.Batch(tickEvery(), probeCmd(m.root))
}

func (m tuiModel) Update(msg tea.Msg) (tea.Model, tea.Cmd) {
	switch msg := msg.(type) {
	case tickMsg:
		if m.busy {
			return m, tickEvery()
		}
		return m, tea.Batch(tickEvery(), probeCmd(m.root))

	case probedMsg:
		if !m.busy {
			m.rows = []srvState(msg)
			if m.cursor >= len(m.rows) {
				m.cursor = len(m.rows) - 1
			}
		}
		return m, nil

	case actionDoneMsg:
		m.busy = false
		m.message = string(msg)
		return m, probeCmd(m.root)

	case tea.KeyMsg:
		return m.onKey(msg.String())
	}
	return m, nil
}

func (m tuiModel) onKey(key string) (tea.Model, tea.Cmd) {
	switch key {
	case "q", "ctrl+c", "esc":
		m.quitting = true
		return m, tea.Quit
	case "up", "k":
		if m.cursor > 0 {
			m.cursor--
		}
		return m, nil
	case "down", "j":
		if m.cursor < len(m.rows)-1 {
			m.cursor++
		}
		return m, nil
	}
	if m.busy || len(m.rows) == 0 {
		return m, nil // ignore actions mid-operation
	}
	sel := m.rows[m.cursor].srv
	switch key {
	case "s":
		m.busy, m.message = true, "starting "+sel.Name+"…"
		return m, actionCmd(m.root, "start", sel)
	case "x":
		m.busy, m.message = true, "stopping "+sel.Name+"…"
		return m, actionCmd(m.root, "stop", sel)
	case "r":
		m.busy, m.message = true, "hot-swapping "+sel.Name+"…"
		return m, actionCmd(m.root, "restart", sel)
	case "S":
		m.busy, m.message = true, "starting all…"
		return m, actionAllCmd(m.root, "start")
	case "X":
		m.busy, m.message = true, "stopping all…"
		return m, actionAllCmd(m.root, "stop")
	case "R":
		m.busy, m.message = true, "hot-swapping all…"
		return m, actionAllCmd(m.root, "restart")
	}
	return m, nil
}

func (m tuiModel) View() string {
	if m.quitting {
		return "mcpd — servers left running in the background.\n" +
			"  `mcpd status` to check · `mcpd stop` to stop.\n"
	}
	var b strings.Builder
	b.WriteString(titleStyle.Render("mcpd · MCP server control") + "\n\n")
	b.WriteString("  " + headerStyle.Render(fmt.Sprintf("%-5s  %-5s  %-7s  %-9s  %s", "NAME", "PORT", "PID", "STATE", "URL")) + "\n")
	for i, r := range m.rows {
		marker, name := "  ", fmt.Sprintf("%-5s", r.srv.Name)
		if i == m.cursor {
			marker = selStyle.Render("▸ ")
			name = selStyle.Render(name)
		}
		pid := "-"
		if r.live {
			pid = strconv.Itoa(r.pid)
		}
		label := stateWord(r.live, r.listening)
		state := stateStyle(label).Render(fmt.Sprintf("%-9s", label))
		url := dimStyle.Render(fmt.Sprintf("http://localhost:%d/", r.srv.Port))
		b.WriteString(fmt.Sprintf("%s%s  %-5d  %-7s  %s  %s\n", marker, name, r.srv.Port, pid, state, url))
	}
	b.WriteString("\n")
	if m.message != "" {
		prefix := ""
		if m.busy {
			prefix = "⏳ "
		}
		b.WriteString(msgStyle.Render(prefix+m.message) + "\n\n")
	}
	b.WriteString(dimStyle.Render("↑/↓ select  ·  s start  ·  x stop  ·  r restart (hot-swap)") + "\n")
	b.WriteString(dimStyle.Render("S/X/R all  ·  q quit (leaves servers running)") + "\n")
	return docStyle.Render(b.String())
}

// --- commands & helpers ------------------------------------------------------

func tickEvery() tea.Cmd {
	return tea.Tick(time.Second, func(t time.Time) tea.Msg { return tickMsg(t) })
}

func probeCmd(root string) tea.Cmd {
	return func() tea.Msg { return probedMsg(probeAll(root)) }
}

func probeAll(root string) []srvState {
	var out []srvState
	for _, s := range servers(root) {
		st := srvState{srv: s}
		if pid, ok := readPid(s, root); ok && processAlive(pid) {
			st.pid, st.live = pid, true
		}
		st.listening = portListening(s.Port, 200*time.Millisecond)
		out = append(out, st)
	}
	return out
}

// actionCmd / actionAllCmd run a mutation in the background (Bubble Tea runs the
// returned func in a goroutine) under the orchestrator lock, then report a one-
// line result. The TUI always manages servers detached.
func actionCmd(root, kind string, s Server) tea.Cmd {
	return func() tea.Msg {
		unlock, err := acquireOrchestratorLock(root)
		if err != nil {
			return actionDoneMsg(err.Error())
		}
		defer unlock()
		if err := doAction(kind, s, root); err != nil {
			return actionDoneMsg(firstLine(err.Error()))
		}
		return actionDoneMsg(fmt.Sprintf("%s %s", s.Name, pastTense(kind)))
	}
}

func actionAllCmd(root, kind string) tea.Cmd {
	return func() tea.Msg {
		unlock, err := acquireOrchestratorLock(root)
		if err != nil {
			return actionDoneMsg(err.Error())
		}
		defer unlock()
		for _, s := range servers(root) {
			if err := doAction(kind, s, root); err != nil {
				return actionDoneMsg(firstLine(err.Error()))
			}
		}
		return actionDoneMsg("all servers " + pastTense(kind))
	}
}

// doAction is the detached single-server mutation shared by the TUI key actions.
func doAction(kind string, s Server, root string) error {
	switch kind {
	case "start":
		if isRunning(s, root) {
			return nil
		}
		if err := ensureBuilt(s, root); err != nil {
			return err
		}
		if err := waitStartable(s); err != nil {
			return err
		}
		_, err := startOne(s, root, true)
		return err
	case "stop":
		_, err := stopServer(s, root, stopGrace)
		return err
	case "restart":
		_, err := restartServer(s, root, true)
		return err
	}
	return nil
}

func stateStyle(label string) lipgloss.Style {
	switch label {
	case "running":
		return runningStyle
	case "starting":
		return startingStyle
	case "foreign":
		return foreignStyle
	default:
		return stoppedStyle
	}
}

func pastTense(kind string) string {
	switch kind {
	case "start":
		return "started"
	case "stop":
		return "stopped"
	case "restart":
		return "restarted"
	}
	return kind
}

func firstLine(s string) string {
	if i := strings.IndexByte(s, '\n'); i >= 0 {
		return s[:i] + " …"
	}
	return s
}
