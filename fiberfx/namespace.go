package fiberfx

import (
	"fmt"
	"sync"
)

// Namespace is a 3-character entity type identifier.
type Namespace string

// String returns the namespace prefix.
func (ns Namespace) String() string { return string(ns) }

// Valid checks if the namespace is registered.
func (ns Namespace) Valid() bool { return registry.has(ns) }

// Description returns the namespace description if registered.
func (ns Namespace) Description() string { return registry.description(ns) }

// namespaceRegistry holds registered namespaces with descriptions.
type namespaceRegistry struct {
	mu    sync.RWMutex
	names map[Namespace]string
}

var registry = &namespaceRegistry{
	names: make(map[Namespace]string),
}

// Register adds a namespace to the registry.
// Returns error if namespace is invalid or already registered.
func Register(ns Namespace, description string) error {
	if len(ns) != NamespaceLen {
		return fmt.Errorf("namespace must be %d characters", NamespaceLen)
	}
	for _, c := range ns {
		if c < 'A' || c > 'Z' {
			return fmt.Errorf("namespace must be uppercase letters: got %q", ns)
		}
	}

	registry.mu.Lock()
	defer registry.mu.Unlock()

	if _, exists := registry.names[ns]; exists {
		return fmt.Errorf("namespace %q already registered", ns)
	}
	registry.names[ns] = description
	return nil
}

// MustRegister registers a namespace, panicking on error.
func MustRegister(ns Namespace, description string) Namespace {
	if err := Register(ns, description); err != nil {
		panic(err)
	}
	return ns
}

// Registered returns all registered namespaces.
func Registered() []Namespace {
	registry.mu.RLock()
	defer registry.mu.RUnlock()

	result := make([]Namespace, 0, len(registry.names))
	for ns := range registry.names {
		result = append(result, ns)
	}
	return result
}

// IsRegistered checks if a namespace is in the registry.
func IsRegistered(ns Namespace) bool {
	return registry.has(ns)
}

func (r *namespaceRegistry) has(ns Namespace) bool {
	r.mu.RLock()
	defer r.mu.RUnlock()
	_, ok := r.names[ns]
	return ok
}

func (r *namespaceRegistry) description(ns Namespace) string {
	r.mu.RLock()
	defer r.mu.RUnlock()
	return r.names[ns]
}

// Atlas-specific namespaces - registered at init time
var (
	// Schema entities
	NS_TABLE  = MustRegister("TBL", "Database table")
	NS_COLUMN = MustRegister("COL", "Table column")
	NS_INDEX  = MustRegister("IDX", "Database index")
	NS_FKEY   = MustRegister("FKY", "Foreign key constraint")

	// User-defined entities (common patterns)
	NS_USER    = MustRegister("USR", "User entity")
	NS_SESSION = MustRegister("SES", "Session entity")
	NS_TASK    = MustRegister("TSK", "Task entity")
	NS_ORDER   = MustRegister("ORD", "Order entity")
	NS_PRODUCT = MustRegister("PRD", "Product entity")
	NS_EVENT   = MustRegister("EVT", "Event entity")
	NS_MESSAGE = MustRegister("MSG", "Message entity")
	NS_FILE    = MustRegister("FIL", "File entity")

	// Planning & Roadmap (MCP domain)
	NS_EPIC      = MustRegister("EPC", "Epic entity")
	NS_FEATURE   = MustRegister("FTR", "Feature entity")
	NS_USERSTORY = MustRegister("USS", "User story entity")
	NS_PLAN      = MustRegister("PLN", "Plan entity")

	// Knowledge Base
	NS_KB = MustRegister("KBI", "Knowledge Base Index")
)

// IsValidNamespace checks if a namespace is registered.
// Alias for IsRegistered for API compatibility.
func IsValidNamespace(ns Namespace) bool {
	return IsRegistered(ns)
}

// AllNamespaces returns all registered namespaces.
// Alias for Registered for API compatibility.
func AllNamespaces() []Namespace {
	return Registered()
}
