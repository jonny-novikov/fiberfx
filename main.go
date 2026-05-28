// main.go - Jonnify Edge Server
// Serves static distribution files (litestream, flyer)
package main

import (
	"fmt"
	"log"
	"os"
	"path/filepath"
	"strconv"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

var (
	version   = "0.1.0"
	distrDir  = "/app/distr"
	indexHTML = "/app/index.html"
	egeDir    = "/app/ege"
	eduDir    = "/app/edu"
	schoolDir = "/app/school"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	// Allow override for local dev
	if dir := os.Getenv("DISTR_DIR"); dir != "" {
		distrDir = dir
	}
	if path := os.Getenv("INDEX_HTML"); path != "" {
		indexHTML = path
	}
	if dir := os.Getenv("EGE_DIR"); dir != "" {
		egeDir = dir
	}
	if dir := os.Getenv("EDU_DIR"); dir != "" {
		eduDir = dir
	}
	if dir := os.Getenv("SCHOOL_DIR"); dir != "" {
		schoolDir = dir
	}

	app := fiber.New(fiber.Config{
		AppName:               "jonnify",
		DisableStartupMessage: false,
	})

	// Middleware
	app.Use(recover.New())
	app.Use(logger.New(logger.Config{
		Format: "[${time}] ${status} ${method} ${path} ${latency}\n",
	}))

	// Health check
	app.Get("/health", func(c *fiber.Ctx) error {
		return c.JSON(fiber.Map{"status": "ok", "version": version})
	})

	// Serve index.html at root
	app.Get("/", func(c *fiber.Ctx) error {
		return c.SendFile(indexHTML)
	})

	// List available distributions
	app.Get("/files", func(c *fiber.Ctx) error {
		files := make([]fiber.Map, 0)

		// Walk distr directory
		err := filepath.Walk(distrDir, func(path string, info os.FileInfo, err error) error {
			if err != nil {
				return nil // Skip errors
			}
			if info.IsDir() {
				return nil
			}

			relPath, _ := filepath.Rel(distrDir, path)
			files = append(files, fiber.Map{
				"name":     relPath,
				"size":     info.Size(),
				"modified": info.ModTime(),
				"url":      "/distr/" + relPath,
			})
			return nil
		})
		if err != nil {
			log.Printf("Error listing files: %v", err)
		}

		return c.JSON(fiber.Map{
			"version": version,
			"files":   files,
			"count":   len(files),
		})
	})

	// Serve EGE materials at clean route URLs (no .html extension).
	//   /ege               → ege/index.html
	//   /ege/<name>        → ege/<name>.html  (e.g. /ege/stereometria → ege/stereometria.html)
	serveEge := func(c *fiber.Ctx, name string) error {
		if name == "" {
			name = "index"
		}
		fullPath := filepath.Join(egeDir, name+".html")
		cleanPath := filepath.Clean(fullPath)
		if len(cleanPath) < len(egeDir) || cleanPath[:len(egeDir)] != egeDir {
			return c.Status(403).JSON(fiber.Map{"error": "access denied"})
		}
		if _, err := os.Stat(cleanPath); err != nil {
			return c.Status(404).JSON(fiber.Map{"error": "ege page not found: " + name})
		}
		// SendFile auto-sets Last-Modified + handles If-Modified-Since (304).
		c.Set("Cache-Control", "public, max-age=300, must-revalidate")
		return c.SendFile(cleanPath)
	}
	app.Get("/ege", func(c *fiber.Ctx) error {
		return serveEge(c, "")
	})
	app.Get("/ege/:name", func(c *fiber.Ctx) error {
		return serveEge(c, c.Params("name"))
	})

	// Serve EDU materials at clean route URLs (no .html extension).
	//   /edu            → edu/finances.html  (canonical course landing)
	//   /edu/finances   → edu/finances.html
	//   /edu/<name>     → edu/<name>.html
	serveEdu := func(c *fiber.Ctx, name string) error {
		if name == "" {
			name = "finances"
		}
		fullPath := filepath.Join(eduDir, name+".html")
		cleanPath := filepath.Clean(fullPath)
		if len(cleanPath) < len(eduDir) || cleanPath[:len(eduDir)] != eduDir {
			return c.Status(403).JSON(fiber.Map{"error": "access denied"})
		}
		if _, err := os.Stat(cleanPath); err != nil {
			return c.Status(404).JSON(fiber.Map{"error": "edu page not found: " + name})
		}
		c.Set("Cache-Control", "public, max-age=300, must-revalidate")
		return c.SendFile(cleanPath)
	}
	app.Get("/edu", func(c *fiber.Ctx) error {
		return serveEdu(c, "")
	})
	app.Get("/edu/:name", func(c *fiber.Ctx) error {
		return serveEdu(c, c.Params("name"))
	})

	// Serve SCHOOL materials at clean route URLs (no .html extension).
	//   /school          → school/index.html
	//   /school/<name>   → school/<name>.html  (e.g. /school/sharygin-pokolenia)
	serveSchool := func(c *fiber.Ctx, name string) error {
		if name == "" {
			name = "index"
		}
		fullPath := filepath.Join(schoolDir, name+".html")
		cleanPath := filepath.Clean(fullPath)
		if len(cleanPath) < len(schoolDir) || cleanPath[:len(schoolDir)] != schoolDir {
			return c.Status(403).JSON(fiber.Map{"error": "access denied"})
		}
		if _, err := os.Stat(cleanPath); err != nil {
			return c.Status(404).JSON(fiber.Map{"error": "school page not found: " + name})
		}
		c.Set("Cache-Control", "public, max-age=300, must-revalidate")
		return c.SendFile(cleanPath)
	}
	app.Get("/school", func(c *fiber.Ctx) error {
		return serveSchool(c, "")
	})
	app.Get("/school/:name", func(c *fiber.Ctx) error {
		return serveSchool(c, c.Params("name"))
	})

	// Serve distribution files with proper headers
	app.Get("/distr/*", func(c *fiber.Ctx) error {
		filePath := c.Params("*")
		if filePath == "" {
			return c.Status(400).JSON(fiber.Map{"error": "file path required"})
		}

		fullPath := filepath.Join(distrDir, filePath)

		// Security: ensure path is within distrDir
		cleanPath := filepath.Clean(fullPath)
		if len(cleanPath) < len(distrDir) || cleanPath[:len(distrDir)] != distrDir {
			return c.Status(403).JSON(fiber.Map{"error": "access denied"})
		}

		// Check file exists
		info, err := os.Stat(fullPath)
		if err != nil {
			return c.Status(404).JSON(fiber.Map{"error": "file not found: " + filePath})
		}

		// Set headers
		c.Set("Content-Type", "application/gzip")
		c.Set("Content-Length", strconv.FormatInt(info.Size(), 10))
		c.Set("Content-Disposition", fmt.Sprintf("attachment; filename=%q", filepath.Base(filePath)))
		c.Set("Cache-Control", "public, max-age=31536000, immutable") // 1 year cache

		return c.SendFile(fullPath)
	})

	log.Printf("Starting jonnify v%s on port %s, distr: %s, index: %s, ege: %s, edu: %s, school: %s", version, port, distrDir, indexHTML, egeDir, eduDir, schoolDir)
	log.Fatal(app.Listen(":" + port))
}
