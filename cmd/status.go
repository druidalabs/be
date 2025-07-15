package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/druidalabs/be/internal/config"
	"github.com/druidalabs/be/pkg/client"
)

var statusCmd = &cobra.Command{
	Use:   "status",
	Short: "Check account status and token validity",
	Long: `Check your account status, token validity, and rate limit information.

Example:
  be status`,
	Run: func(cmd *cobra.Command, args []string) {
		if err := runStatus(); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	},
}

func init() {
	rootCmd.AddCommand(statusCmd)
}

func runStatus() error {
	// Load config
	cfg, err := config.LoadConfig()
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	if cfg.APIToken == "" {
		fmt.Println("❌ Not signed up yet")
		fmt.Println("Run 'be signup' to create an account")
		return nil
	}

	// Check local token validity
	if !config.IsTokenValid(cfg) {
		fmt.Println("❌ Local token has expired")
		fmt.Println("Run 'be signup' to refresh your token")
		return nil
	}

	// Create client and check status
	apiURL := viper.GetString("api-url")
	client := client.NewClient(apiURL)
	client.SetToken(cfg.APIToken)

	fmt.Println("Checking status...")
	resp, err := client.Status()
	if err != nil {
		return fmt.Errorf("status check failed: %w", err)
	}

	// Display status
	fmt.Printf("Status: %s\n", resp.Status)
	fmt.Printf("User ID: %s\n", resp.UserID)
	
	if resp.TokenValid {
		fmt.Println("✓ Token is valid")
		fmt.Printf("Token expires: %s\n", resp.ExpiresAt.Format("2006-01-02 15:04:05"))
	} else {
		fmt.Println("❌ Token is invalid")
		fmt.Println("Run 'be signup' to refresh your token")
	}

	// Rate limit info
	fmt.Printf("\nRate Limit:\n")
	fmt.Printf("  Limit: %d requests\n", resp.RateLimit.Limit)
	fmt.Printf("  Remaining: %d requests\n", resp.RateLimit.Remaining)
	fmt.Printf("  Reset: %s\n", resp.RateLimit.Reset.Format("2006-01-02 15:04:05"))

	fmt.Printf("\nServer Time: %s\n", resp.ServerTime.Format("2006-01-02 15:04:05"))

	return nil
}