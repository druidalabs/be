const rateLimit = require('express-rate-limit');

// Rate limit for signup endpoint
const signupLimiter = rateLimit({
  windowMs: 60 * 60 * 1000, // 1 hour
  max: 5, // limit each IP to 5 signup attempts per hour
  message: {
    error: 'Too Many Requests',
    code: 429,
    message: 'Too many signup attempts from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limit for authenticated endpoints
const authenticatedLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 30, // limit each IP to 30 requests per minute
  message: {
    error: 'Too Many Requests',
    code: 429,
    message: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

// Rate limit for send endpoint (more restrictive)
const sendLimiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 10, // limit each IP to 10 send requests per minute
  message: {
    error: 'Too Many Requests',
    code: 429,
    message: 'Too many send requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

module.exports = {
  signupLimiter,
  authenticatedLimiter,
  sendLimiter
};