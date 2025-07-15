package types

import "time"

type Config struct {
	APIToken   string    `json:"api_token"`
	APIURL     string    `json:"api_url"`
	UserID     string    `json:"user_id"`
	ExpiresAt  time.Time `json:"expires_at"`
	CreatedAt  time.Time `json:"created_at"`
	LastUsed   time.Time `json:"last_used"`
}

type SignupRequest struct {
	Username string `json:"username"`
	Email    string `json:"email"`
}

type SignupResponse struct {
	Token     string    `json:"token"`
	UserID    string    `json:"user_id"`
	ExpiresAt time.Time `json:"expires_at"`
	Message   string    `json:"message"`
}

type StatusResponse struct {
	Status      string    `json:"status"`
	UserID      string    `json:"user_id"`
	TokenValid  bool      `json:"token_valid"`
	ExpiresAt   time.Time `json:"expires_at"`
	RateLimit   RateLimit `json:"rate_limit"`
	ServerTime  time.Time `json:"server_time"`
}

type RateLimit struct {
	Limit     int       `json:"limit"`
	Remaining int       `json:"remaining"`
	Reset     time.Time `json:"reset"`
}

type SendRequest struct {
	Amount    int64  `json:"amount"`
	ToAddress string `json:"to_address"`
	Message   string `json:"message,omitempty"`
}

type SendResponse struct {
	TransactionID string `json:"transaction_id"`
	Status        string `json:"status"`
	Message       string `json:"message"`
}

type ErrorResponse struct {
	Error   string `json:"error"`
	Code    int    `json:"code"`
	Message string `json:"message"`
}