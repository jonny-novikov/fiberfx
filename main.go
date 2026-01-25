// main.go - Jonnify Edge Server
// Serves .gar.gz files from Fly.io volume
package main

import (
	"log"
	"os"

	"github.com/gofiber/fiber/v2"
	"github.com/gofiber/fiber/v2/middleware/logger"
	"github.com/gofiber/fiber/v2/middleware/recover"
)

func main() {
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	dataDir := os.Getenv("DATA_DIR")
	if dataDir == "" {
		dataDir = "/data"
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
		return c.JSON(fiber.Map{"status": "ok"})
	})

	// Serve .gar.gz files from volume
	app.Static("/files", dataDir, fiber.Static{
		Browse:   false,
		Download: true,
	})

	// List available files
	app.Get("/", func(c *fiber.Ctx) error {
		entries, err := os.ReadDir(dataDir)
		if err != nil {
			return c.Status(500).JSON(fiber.Map{
				"error": "failed to read data directory",
			})
		}

		files := make([]fiber.Map, 0)
		for _, entry := range entries {
			if !entry.IsDir() {
				info, _ := entry.Info()
				files = append(files, fiber.Map{
					"name": entry.Name(),
					"size": info.Size(),
					"url":  "/files/" + entry.Name(),
				})
			}
		}

		return c.JSON(fiber.Map{
			"files": files,
			"count": len(files),
		})
	})

	log.Printf("Starting jonnify on port %s, serving from %s", port, dataDir)
	log.Fatal(app.Listen(":" + port))
}
