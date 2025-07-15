package client

import (
	"bytes"
	"encoding/json"
	"fmt"
	"io"
	"net/http"
	"time"

	"github.com/druidalabs/be/pkg/types"
)

const (
	DefaultTimeout = 30 * time.Second
	UserAgent      = "be-cli/1.0"
)

type Client struct {
	BaseURL    string
	HTTPClient *http.Client
	Token      string
}

func NewClient(baseURL string) *Client {
	return &Client{
		BaseURL: baseURL,
		HTTPClient: &http.Client{
			Timeout: DefaultTimeout,
		},
	}
}

func (c *Client) SetToken(token string) {
	c.Token = token
}

func (c *Client) doRequest(method, endpoint string, body interface{}, result interface{}) error {
	var requestBody io.Reader
	if body != nil {
		jsonBody, err := json.Marshal(body)
		if err != nil {
			return fmt.Errorf("failed to marshal request body: %w", err)
		}
		requestBody = bytes.NewBuffer(jsonBody)
	}

	url := fmt.Sprintf("%s/api/v1%s", c.BaseURL, endpoint)
	req, err := http.NewRequest(method, url, requestBody)
	if err != nil {
		return fmt.Errorf("failed to create request: %w", err)
	}

	req.Header.Set("Content-Type", "application/json")
	req.Header.Set("User-Agent", UserAgent)
	
	if c.Token != "" {
		req.Header.Set("Authorization", fmt.Sprintf("Bearer %s", c.Token))
	}

	resp, err := c.HTTPClient.Do(req)
	if err != nil {
		return fmt.Errorf("request failed: %w", err)
	}
	defer resp.Body.Close()

	responseBody, err := io.ReadAll(resp.Body)
	if err != nil {
		return fmt.Errorf("failed to read response body: %w", err)
	}

	if resp.StatusCode >= 400 {
		var errorResp types.ErrorResponse
		if err := json.Unmarshal(responseBody, &errorResp); err != nil {
			return fmt.Errorf("HTTP %d: %s", resp.StatusCode, string(responseBody))
		}
		return fmt.Errorf("API error: %s", errorResp.Message)
	}

	if result != nil {
		if err := json.Unmarshal(responseBody, result); err != nil {
			return fmt.Errorf("failed to unmarshal response: %w", err)
		}
	}

	return nil
}

func (c *Client) Signup(username, email string) (*types.SignupResponse, error) {
	req := types.SignupRequest{
		Username: username,
		Email:    email,
	}

	var resp types.SignupResponse
	if err := c.doRequest("POST", "/signup", req, &resp); err != nil {
		return nil, err
	}

	return &resp, nil
}

func (c *Client) Status() (*types.StatusResponse, error) {
	var resp types.StatusResponse
	if err := c.doRequest("GET", "/status", nil, &resp); err != nil {
		return nil, err
	}

	return &resp, nil
}

func (c *Client) Send(amount int64, toAddress string, message string) (*types.SendResponse, error) {
	req := types.SendRequest{
		Amount:    amount,
		ToAddress: toAddress,
		Message:   message,
	}

	var resp types.SendResponse
	if err := c.doRequest("POST", "/send", req, &resp); err != nil {
		return nil, err
	}

	return &resp, nil
}