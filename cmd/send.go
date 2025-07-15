package cmd

import (
	"fmt"
	"os"
	"strconv"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"

	"github.com/druidalabs/be/internal/config"
	"github.com/druidalabs/be/pkg/client"
)

var (
	sendMessage string
)

var sendCmd = &cobra.Command{
	Use:   "send <amount> <address>",
	Short: "Send Bitcoin Efectivo to an address",
	Long: `Send Bitcoin Efectivo to a specified address.
Amount should be specified in satoshis.

Example:
  be send 100000 bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh
  be send 100000 bc1qxy2kgdygjrsqtzq2n0yrf2493p83kkfjhx0wlh --message "Payment for services"`,
	Args: cobra.ExactArgs(2),
	Run: func(cmd *cobra.Command, args []string) {
		if err := runSend(args[0], args[1]); err != nil {
			fmt.Fprintf(os.Stderr, "Error: %v\n", err)
			os.Exit(1)
		}
	},
}

func init() {
	rootCmd.AddCommand(sendCmd)
	sendCmd.Flags().StringVarP(&sendMessage, "message", "m", "", "Optional message to include with the transaction")
}

func runSend(amountStr, address string) error {
	// Parse amount
	amount, err := strconv.ParseInt(amountStr, 10, 64)
	if err != nil {
		return fmt.Errorf("invalid amount: %w", err)
	}

	if amount <= 0 {
		return fmt.Errorf("amount must be positive")
	}

	// Load config
	cfg, err := config.LoadConfig()
	if err != nil {
		return fmt.Errorf("failed to load config: %w", err)
	}

	if cfg.APIToken == "" {
		return fmt.Errorf("not signed up yet. Run 'be signup' to create an account")
	}

	if !config.IsTokenValid(cfg) {
		return fmt.Errorf("token has expired. Run 'be signup' to refresh your token")
	}

	// Create client and send
	apiURL := viper.GetString("api-url")
	client := client.NewClient(apiURL)
	client.SetToken(cfg.APIToken)

	fmt.Printf("Sending %d satoshis to %s...\n", amount, address)
	if sendMessage != "" {
		fmt.Printf("Message: %s\n", sendMessage)
	}

	resp, err := client.Send(amount, address, sendMessage)
	if err != nil {
		return fmt.Errorf("send failed: %w", err)
	}

	fmt.Println("✓ Transaction sent successfully!")
	fmt.Printf("Transaction ID: %s\n", resp.TransactionID)
	fmt.Printf("Status: %s\n", resp.Status)
	if resp.Message != "" {
		fmt.Printf("Message: %s\n", resp.Message)
	}

	return nil
}