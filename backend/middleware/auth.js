const jwt = require('jsonwebtoken');
const { users } = require('../models/user');

const JWT_SECRET = process.env.JWT_SECRET || 'your-secret-key-change-this-in-production';

const authMiddleware = (req, res, next) => {
  const authHeader = req.headers.authorization;
  
  if (!authHeader || !authHeader.startsWith('Bearer ')) {
    return res.status(401).json({
      error: 'Unauthorized',
      code: 401,
      message: 'No valid authorization token provided'
    });
  }
  
  const token = authHeader.substring(7); // Remove 'Bearer ' prefix
  
  try {
    const decoded = jwt.verify(token, JWT_SECRET);
    const user = users.find(u => u.id === decoded.userId);
    
    if (!user) {
      return res.status(401).json({
        error: 'Unauthorized',
        code: 401,
        message: 'Invalid token - user not found'
      });
    }
    
    if (new Date() > new Date(user.expiresAt)) {
      return res.status(401).json({
        error: 'Unauthorized',
        code: 401,
        message: 'Token has expired'
      });
    }
    
    req.user = user;
    next();
  } catch (error) {
    return res.status(401).json({
      error: 'Unauthorized',
      code: 401,
      message: 'Invalid token'
    });
  }
};

module.exports = authMiddleware;