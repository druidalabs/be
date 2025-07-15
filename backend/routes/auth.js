const express = require('express');
const jwt = require('jsonwebtoken');
const Joi = require('joi');
const { signupLimiter } = require('../middleware/rateLimit');
const { createUser } = require('../models/user');

const router = express.Router();
const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-this-in-production';

// Validation schema
const signupSchema = Joi.object({
  username: Joi.string().alphanum().min(3).max(30).required(),
  email: Joi.string().email().required()
});

// POST /api/v1/signup
router.post('/signup', signupLimiter, async (req, res) => {
  try {
    const { error, value } = signupSchema.validate(req.body);
    
    if (error) {
      return res.status(400).json({
        error: 'Validation Error',
        code: 400,
        message: error.details[0].message
      });
    }
    
    const { username, email } = value;
    
    // Create user
    const user = await createUser(username, email);
    
    // Generate JWT token
    const token = jwt.sign(
      { userId: user.id, username: user.username },
      JWT_SECRET,
      { expiresIn: '30d' }
    );
    
    res.json({
      token,
      user_id: user.id,
      expires_at: user.expiresAt,
      message: 'Account created successfully. Welcome to Bitcoin Efectivo!'
    });
    
  } catch (error) {
    if (error.message === 'Username or email already exists') {
      return res.status(409).json({
        error: 'Conflict',
        code: 409,
        message: error.message
      });
    }
    
    res.status(500).json({
      error: 'Internal Server Error',
      code: 500,
      message: 'Failed to create account'
    });
  }
});

module.exports = router;