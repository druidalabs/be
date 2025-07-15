fconst express = require('express');
const Joi = require('joi');
const { authenticatedLimiter, sendLimiter } = require('../middleware/rateLimit');
const { 
  updateUserLastUsed,
  createTransaction,
  getUserBalance,
  updateUserBalance
} = require('../models/user');

const router = express.Router();

// Validation schemas
const sendSchema = Joi.object({
  amount: Joi.number().integer().min(1).required(),
  to_address: Joi.string().min(26).max(90).required(),
  message: Joi.string().max(200).optional()
});

// GET /api/v1/status
router.get('/status', authenticatedLimiter, (req, res) => {
  updateUserLastUsed(req.user.id);
  
  const now = new Date();
  const expiresAt = new Date(req.user.expiresAt);
  
  res.json({
    status: 'active',
    user_id: req.user.id,
    token_valid: now < expiresAt,
    expires_at: req.user.expiresAt,
    rate_limit: {
      limit: 30,
      remaining: 25, // This would be calculated based on actual usage
      reset: new Date(now.getTime() + 60000).toISOString()
    },
    server_time: now.toISOString()
  });
});

// POST /api/v1/send
router.post('/send', sendLimiter, (req, res) => {
  try {
    const { error, value } = sendSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        error: 'Validation Error',
        code: 400,
        message: error.details[0].message
      });
    }
    
    const { amount, to_address, message } = value;
    
    // Check balance
    const balance = getUserBalance(req.user.id);
    if (balance < amount) {
      return res.status(400).json({
        error: 'Insufficient Balance',
        code: 400,
        message: `Insufficient balance. Available: ${balance} satoshis`
      });
    }
    
    // Create transaction
    const transaction = createTransaction(req.user.id, amount, to_address, message);
    
    // Update user balance
    updateUserBalance(req.user.id, amount);
    updateUserLastUsed(req.user.id);
    
    res.json({
      transaction_id: transaction.id,
      status: transaction.status,
      message: 'Transaction submitted successfully'
    });
    
  } catch (error) {
    res.status(500).json({
      error: 'Internal Server Error',
      code: 500,
      message: 'Failed to process transaction'
    });
  }
});

// GET /api/v1/balance
router.get('/balance', authenticatedLimiter, (req, res) => {
  updateUserLastUsed(req.user.id);
  
  const balance = getUserBalance(req.user.id);
  
  res.json({
    balance,
    user_id: req.user.id,
    timestamp: new Date().toISOString()
  });
});

module.exports = router;
