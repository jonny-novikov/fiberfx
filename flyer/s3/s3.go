// s3/s3.go
// =============================================================================
// S3 OPERATIONS - Tigris S3 download/upload for FWHD
// =============================================================================

package s3

import (
	"context"
	"fmt"
	"io"
	"os"

	"github.com/aws/aws-sdk-go-v2/aws"
	"github.com/aws/aws-sdk-go-v2/config"
	"github.com/aws/aws-sdk-go-v2/credentials"
	"github.com/aws/aws-sdk-go-v2/service/s3"
)

// Client wraps the S3 client for Tigris operations
type Client struct {
	client   *s3.Client
	bucket   string
	endpoint string
}

// NewClient creates a new S3 client for Tigris
func NewClient() (*Client, error) {
	accessKey := os.Getenv("AWS_ACCESS_KEY_ID")
	secretKey := os.Getenv("AWS_SECRET_ACCESS_KEY")
	endpoint := os.Getenv("AWS_ENDPOINT_URL_S3")
	bucket := os.Getenv("TIGRIS_BUCKET")

	if accessKey == "" || secretKey == "" {
		return nil, fmt.Errorf("AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY must be set")
	}
	if endpoint == "" {
		endpoint = "https://fly.storage.tigris.dev"
	}
	if bucket == "" {
		bucket = "codemoji-distr"
	}

	// Create custom credentials provider
	creds := credentials.NewStaticCredentialsProvider(accessKey, secretKey, "")

	// Load config with custom endpoint
	cfg, err := config.LoadDefaultConfig(context.Background(),
		config.WithCredentialsProvider(creds),
		config.WithRegion("auto"),
	)
	if err != nil {
		return nil, fmt.Errorf("load AWS config: %w", err)
	}

	// Create S3 client with custom endpoint
	client := s3.NewFromConfig(cfg, func(o *s3.Options) {
		o.BaseEndpoint = aws.String(endpoint)
		o.UsePathStyle = true
	})

	return &Client{
		client:   client,
		bucket:   bucket,
		endpoint: endpoint,
	}, nil
}

// Download downloads a file from S3 to local path
func (c *Client) Download(ctx context.Context, key, destPath string) (int64, error) {
	// Create destination file
	file, err := os.Create(destPath)
	if err != nil {
		return 0, fmt.Errorf("create file: %w", err)
	}
	defer file.Close()

	// Download from S3
	result, err := c.client.GetObject(ctx, &s3.GetObjectInput{
		Bucket: aws.String(c.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		return 0, fmt.Errorf("get object: %w", err)
	}
	defer result.Body.Close()

	// Copy to file
	written, err := io.Copy(file, result.Body)
	if err != nil {
		return 0, fmt.Errorf("write file: %w", err)
	}

	return written, nil
}

// Upload uploads a file from local path to S3
func (c *Client) Upload(ctx context.Context, localPath, key string) error {
	file, err := os.Open(localPath)
	if err != nil {
		return fmt.Errorf("open file: %w", err)
	}
	defer file.Close()

	_, err = c.client.PutObject(ctx, &s3.PutObjectInput{
		Bucket: aws.String(c.bucket),
		Key:    aws.String(key),
		Body:   file,
	})
	if err != nil {
		return fmt.Errorf("put object: %w", err)
	}

	return nil
}

// Exists checks if a key exists in S3
func (c *Client) Exists(ctx context.Context, key string) (bool, error) {
	_, err := c.client.HeadObject(ctx, &s3.HeadObjectInput{
		Bucket: aws.String(c.bucket),
		Key:    aws.String(key),
	})
	if err != nil {
		// TODO: Check for specific "not found" error
		return false, nil
	}
	return true, nil
}

// Bucket returns the configured bucket name
func (c *Client) Bucket() string {
	return c.bucket
}

// Endpoint returns the configured endpoint
func (c *Client) Endpoint() string {
	return c.endpoint
}
