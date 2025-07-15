const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');

// In-memory storage for demo purposes
// In production, use a proper database
const users = [];
const transactions = [];

const createUser = async (username, email) => {
  const existingUser = users.find(u => u.username === username || u.email === email);
  
  if (existingUser) {
    throw new Error('Username or email already exists');
  }
  
  const user = {
    id: uuidv4(),
    username,
    email,
    createdAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(), // 30 days
    lastUsed: new Date().toISOString(),
    balance: 1000000 // 1M satoshis for demo
  };
  
  users.push(user);
  return user;
};

const findUserById = (id) => {
  return users.find(u => u.id === id);
};

const updateUserLastUsed = (userId) => {
  const user = findUserById(userId);
  if (user) {
    user.lastUsed = new Date().toISOString();
  }
};

const createTransaction = (userId, amount, toAddress, message) => {
  const transaction = {
    id: uuidv4(),
    userId,
    amount,
    toAddress,
    message,
    status: 'pending',
    createdAt: new Date().toISOString()
  };
  
  transactions.push(transaction);
  
  // Simulate transaction processing
  setTimeout(() => {
    transaction.status = 'completed';
  }, 2000);
  
  return transaction;
};

const getUserBalance = (userId) => {
  const user = findUserById(userId);
  return user ? user.balance : 0;
};

const updateUserBalance = (userId, amount) => {
  const user = findUserById(userId);
  if (user) {
    user.balance -= amount;
  }
};

module.exports = {
  users,
  transactions,
  createUser,
  findUserById,
  updateUserLastUsed,
  createTransaction,
  getUserBalance,
  updateUserBalance
};