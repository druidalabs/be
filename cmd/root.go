package cmd

import (
	"fmt"
	"os"

	"github.com/spf13/cobra"
	"github.com/spf13/viper"
)

var (
	cfgFile string
	apiURL  string
	version = "dev"
)

var rootCmd = &cobra.Command{
	Use:   "be",
	Short: "Bitcoin Efectivo CLI - Interact with the Bitcoin Efectivo network",
	Long: `Bitcoin Efectivo CLI is a command-line tool for interacting with the Bitcoin Efectivo network.
It provides secure, token-based authentication and rate-limited access to network resources.

Visit https://bitcoinefectivo.com to learn more about Bitcoin development tools.`,
	Version: version,
}

func Execute() error {
	return rootCmd.Execute()
}

func init() {
	cobra.OnInitialize(initConfig)

	rootCmd.PersistentFlags().StringVar(&cfgFile, "config", "", "config file (default is $HOME/.be/config.json)")
	rootCmd.PersistentFlags().StringVar(&apiURL, "api-url", "https://api.bitcoinefectivo.com", "API base URL")
	
	viper.BindPFlag("api-url", rootCmd.PersistentFlags().Lookup("api-url"))
}

func initConfig() {
	if cfgFile != "" {
		viper.SetConfigFile(cfgFile)
	} else {
		home, err := os.UserHomeDir()
		if err != nil {
			fmt.Fprintf(os.Stderr, "Error getting home directory: %v\n", err)
			os.Exit(1)
		}

		configDir := home + "/.be"
		if err := os.MkdirAll(configDir, 0755); err != nil {
			fmt.Fprintf(os.Stderr, "Error creating config directory: %v\n", err)
			os.Exit(1)
		}

		viper.AddConfigPath(configDir)
		viper.SetConfigName("config")
		viper.SetConfigType("json")
	}

	viper.AutomaticEnv()

	if err := viper.ReadInConfig(); err == nil {
		fmt.Fprintf(os.Stderr, "Using config file: %s\n", viper.ConfigFileUsed())
	}
}