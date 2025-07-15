package config

import (
	"encoding/json"
	"os"
	"path/filepath"
	"time"

	"github.com/druidalabs/be/pkg/types"
)

const (
	ConfigDir  = ".be"
	ConfigFile = "config.json"
)

func GetConfigPath() (string, error) {
	home, err := os.UserHomeDir()
	if err != nil {
		return "", err
	}
	
	configDir := filepath.Join(home, ConfigDir)
	if err := os.MkdirAll(configDir, 0755); err != nil {
		return "", err
	}
	
	return filepath.Join(configDir, ConfigFile), nil
}

func LoadConfig() (*types.Config, error) {
	configPath, err := GetConfigPath()
	if err != nil {
		return nil, err
	}
	
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return &types.Config{}, nil
	}
	
	data, err := os.ReadFile(configPath)
	if err != nil {
		return nil, err
	}
	
	var config types.Config
	if err := json.Unmarshal(data, &config); err != nil {
		return nil, err
	}
	
	return &config, nil
}

func SaveConfig(config *types.Config) error {
	configPath, err := GetConfigPath()
	if err != nil {
		return err
	}
	
	config.LastUsed = time.Now()
	
	data, err := json.MarshalIndent(config, "", "  ")
	if err != nil {
		return err
	}
	
	return os.WriteFile(configPath, data, 0600)
}

func IsTokenValid(config *types.Config) bool {
	return config.APIToken != "" && time.Now().Before(config.ExpiresAt)
}

func ClearConfig() error {
	configPath, err := GetConfigPath()
	if err != nil {
		return err
	}
	
	if _, err := os.Stat(configPath); os.IsNotExist(err) {
		return nil
	}
	
	return os.Remove(configPath)
}