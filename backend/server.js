const express = require('express');
const helmet = require('helmet');
const cors = require('cors');
const morgan = require('morgan');
const rateLimit = require('express-rate-limit');
require('dotenv').config();

const authMiddleware = require('./middleware/auth');
const rateLimitMiddleware = require('./middleware/rateLimit');
const errorHandler = require('./middleware/errorHandler');

const authRoutes = require('./routes/auth');
const apiRoutes = require('./routes/api');

const app = express();
const PORT = process.env.PORT || 3000;

// Security middleware
app.use(helmet());
app.use(cors({
  origin: process.env.CORS_ORIGIN || 'https://bitcoinefectivo.com',
  credentials: true
}));

// Logging
app.use(morgan('combined'));

// Body parsing
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Block browser requests (prevent CSRF and abuse)
app.use((req, res, next) => {
  const userAgent = req.get('User-Agent') || '';
  
  // Allow CLI requests
  if (userAgent.includes('be-cli/') || userAgent.includes('curl/')) {
    return next();
  }
  
  // Block obvious browser requests
  if (userAgent.includes('Mozilla/') || userAgent.includes('Chrome/') || userAgent.includes('Safari/')) {
    return res.status(403).json({
      error: 'Forbidden',
      code: 403,
      message: 'Browser requests are not allowed. Use the Bitcoin Efectivo CLI.'
    });
  }
  
  next();
});

// Global rate limiting
const globalLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100, // limit each IP to 100 requests per windowMs
  message: {
    error: 'Too Many Requests',
    code: 429,
    message: 'Too many requests from this IP, please try again later.'
  },
  standardHeaders: true,
  legacyHeaders: false,
});

app.use('/api', globalLimiter);

// Health check
app.get('/health', (req, res) => {
  res.json({
    status: 'ok',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// Routes
app.use('/api/v1', authRoutes);
app.use('/api/v1', authMiddleware, apiRoutes);

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    error: 'Not Found',
    code: 404,
    message: 'The requested resource was not found.'
  });
});

// Error handler
app.use(errorHandler);

// Start server
app.listen(PORT, () => {
  console.log(`Bitcoin Efectivo API server running on port ${PORT}`);
  console.log(`Environment: ${process.env.NODE_ENV || 'development'}`);
});