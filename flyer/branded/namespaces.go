// branded/namespaces.go
// =============================================================================
// NAMESPACES - FWHD Domain Namespace Definitions
// =============================================================================
//
// Defines all FWHD-specific namespaces for branded IDs.
// Each namespace is a 3-character prefix identifying the entity type.
//
// =============================================================================

package branded

// Namespace is a 3-character entity type identifier.
type Namespace string

const (
	// FWHD Domain Namespaces
	NS_PACKAGE    Namespace = "PKG" // Package - built artifact (tar.gz on Tigris)
	NS_RELEASE    Namespace = "RLS" // Release - deployable version (tagged package)
	NS_DEPLOYMENT Namespace = "DPL" // Deployment - audit record of deploy action
	NS_COMMAND    Namespace = "CMD" // Command - deploy command
)

// ValidNamespaces for validation
var ValidNamespaces = map[Namespace]bool{
	NS_PACKAGE:    true,
	NS_RELEASE:    true,
	NS_DEPLOYMENT: true,
	NS_COMMAND:    true,
}

// IsValidNamespace checks if a namespace is valid.
func IsValidNamespace(ns Namespace) bool {
	return ValidNamespaces[ns]
}

// AllNamespaces returns all valid namespaces.
func AllNamespaces() []Namespace {
	return []Namespace{
		NS_PACKAGE,
		NS_RELEASE,
		NS_DEPLOYMENT,
		NS_COMMAND,
	}
}

// NamespaceDescriptions provides human-readable descriptions
var NamespaceDescriptions = map[Namespace]string{
	NS_PACKAGE:    "Package - Built artifact stored on Tigris S3",
	NS_RELEASE:    "Release - Deployable version with tag",
	NS_DEPLOYMENT: "Deployment - Audit record of deploy action",
	NS_COMMAND:    "Command - Deploy command",
}
