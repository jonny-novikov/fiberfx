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
	version  = "0.1.0"
	distrDir = "/app/distr"
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

	// List available distributions
	app.Get("/", func(c *fiber.Ctx) error {
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

	log.Printf("Starting jonnify v%s on port %s, distr: %s", version, port, distrDir)
	log.Fatal(app.Listen(":" + port))
}
