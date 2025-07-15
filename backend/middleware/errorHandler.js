const errorHandler = (err, req, res, next) => {
  console.error('Error:', err);
  
  // Default error response
  let status = 500;
  let message = 'Internal Server Error';
  
  // Handle specific error types
  if (err.name === 'ValidationError') {
    status = 400;
    message = err.message;
  } else if (err.name === 'JsonWebTokenError') {
    status = 401;
    message = 'Invalid token';
  } else if (err.name === 'TokenExpiredError') {
    status = 401;
    message = 'Token has expired';
  } else if (err.status) {
    status = err.status;
    message = err.message;
  }
  
  res.status(status).json({
    error: 'Error',
    code: status,
    message: message
  });
};

module.exports = errorHandler;