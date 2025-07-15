package cmd

import (
	"fmt"
	"os"
	"strings"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/druidalabs/be/internal/config"
	"github.com/druidalabs/be/pkg/client"
)

var signupCmd = &cobra.Command{
	Use:   "signup",
	Short: "Create a new account and generate API token",
	Long: `Sign up for a new Bitcoin Efectivo account and generate an API token.
This token will be stored locally and used for subsequent API calls.

Example:
  be signup`,
	Run: func(cmd *cobra.Command, args []string) {
		if err := runSignup(); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	},
}

func init() {
	rootCmd.AddCommand(signupCmd)
}

func runSignup() error {
	// Check if already signed up
	cfg, err := config.LoadConfig()
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	if config.IsTokenValid(cfg) {
		fmt.Println("✓ Already signed up and token is valid")
		fmt.Printf("User ID: %s\n", cfg.UserID)
		fmt.Printf("Token expires: %s\n", cfg.ExpiresAt.Format("2006-01-02 15:04:05"))
		return nil
	}

	// Get user input
	fmt.Print("Enter username: ")
	var username string
	if _, err := fmt.Scanln(&username); err != nil {
		return fmt.Errorf("failed to read username: %w", err)
	}

	fmt.Print("Enter email: ")
	var email string
	if _, err := fmt.Scanln(&email); err != nil {
		return fmt.Errorf("failed to read email: %w", err)
	}

	// Validate input
	username = strings.TrimSpace(username)
	email = strings.TrimSpace(email)

	if username == "" {
		return fmt.Errorf("username cannot be empty")
	}

	if email == "" || !strings.Contains(email, "@") {
		return fmt.Errorf("please enter a valid email address")
	}

	// Create client and signup
	apiURL := viper.GetString("api-url")
	client := client.NewClient(apiURL)

	fmt.Println("Creating account...")
	resp, err := client.Signup(username, email)
	if err != nil {
		return fmt.Errorf("signup failed: %w", err)
	}

	// Save config
	cfg.APIToken = resp.Token
	cfg.UserID = resp.UserID
	cfg.ExpiresAt = resp.ExpiresAt
	cfg.APIURL = apiURL

	if err := config.SaveConfig(cfg); err != nil {
		return fmt.Errorf("failed to save config: %w", err)
	}

	fmt.Println("✓ Account created successfully!")
	fmt.Printf("User ID: %s\n", resp.UserID)
	fmt.Printf("Token expires: %s\n", resp.ExpiresAt.Format("2006-01-02 15:04:05"))
	if resp.Message != "" {
		fmt.Printf("Message: %s\n", resp.Message)
	}

	return nil
}