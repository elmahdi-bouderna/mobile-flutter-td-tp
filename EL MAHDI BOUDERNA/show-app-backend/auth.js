// This would be in your Node.js backend project, in routes/auth.js
const express = require('express');
const { body, validationResult } = require('express-validator');
const jwt = require('jsonwebtoken'); // You'll need to install this: npm install jsonwebtoken
const db = require('../database');

const router = express.Router();

// Create users table if it doesn't exist
db.serialize(() => {
  db.run(`
    CREATE TABLE IF NOT EXISTS users (
      id INTEGER PRIMARY KEY AUTOINCREMENT,
      email TEXT UNIQUE NOT NULL,
      password TEXT NOT NULL,
      name TEXT
    )
  `);
  
  // Insert a default user for testing if it doesn't exist
  db.get("SELECT * FROM users WHERE email = 'user@example.com'", [], (err, row) => {
    if (!row) {
      // In production, you should hash passwords. For simplicity, we're storing plaintext here.
      db.run("INSERT INTO users (email, password, name) VALUES (?, ?, ?)", 
        ["user@example.com", "password123", "Test User"]);
    }
  });
});

// User login route
router.post('/login', [
  body('email').isEmail().withMessage('Please enter a valid email'),
  body('password').notEmpty().withMessage('Password is required')
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { email, password } = req.body;

  // Check if user exists and password matches
  db.get("SELECT * FROM users WHERE email = ?", [email], (err, user) => {
    if (err) return res.status(500).json({ error: err.message });
    
    if (!user) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // In production, compare hashed passwords, not plaintext
    if (user.password !== password) {
      return res.status(401).json({ error: 'Invalid email or password' });
    }

    // Generate a JWT token
    const token = jwt.sign(
      { userId: user.id, email: user.email },
      'your_jwt_secret_key', // In production, use an environment variable
      { expiresIn: '24h' }
    );

    res.json({
      token,
      user: {
        id: user.id,
        email: user.email,
        name: user.name
      }
    });
  });
});

// Register user route (optional)
router.post('/register', [
  body('email').isEmail().withMessage('Please enter a valid email'),
  body('password').isLength({ min: 6 }).withMessage('Password must be at least 6 characters'),
  body('name').notEmpty().withMessage('Name is required')
], (req, res) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({ errors: errors.array() });
  }

  const { email, password, name } = req.body;

  // Check if email already exists
  db.get("SELECT id FROM users WHERE email = ?", [email], (err, row) => {
    if (err) return res.status(500).json({ error: err.message });
    
    if (row) {
      return res.status(400).json({ error: 'Email already exists' });
    }

    // Insert new user
    db.run("INSERT INTO users (email, password, name) VALUES (?, ?, ?)",
      [email, password, name], // In production, hash the password
      function (err) {
        if (err) return res.status(500).json({ error: err.message });
        
        // Generate token for new user
        const token = jwt.sign(
          { userId: this.lastID, email },
          'your_jwt_secret_key', // In production, use an environment variable
          { expiresIn: '24h' }
        );

        res.status(201).json({
          token,
          user: {
            id: this.lastID,
            email,
            name
          }
        });
      });
  });
});

module.exports = router;