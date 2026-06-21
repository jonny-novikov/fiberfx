module github.com/fiberfx/echo-courses

go 1.25.0

require (
	github.com/labstack/echo/v5 v5.2.0
	gopkg.in/yaml.v3 v3.0.1
)

require golang.org/x/time v0.14.0 // indirect

// Echo v5 has no published release; it is vendored in this repo at go/echo
// (the v5.2.0 snapshot). Consume it locally and build hermetically with
// GOWORK=off (echo-courses is not a go.work member).
replace github.com/labstack/echo/v5 => ../echo
