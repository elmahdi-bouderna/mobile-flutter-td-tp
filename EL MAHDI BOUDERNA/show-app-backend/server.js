// Add this to your existing server.js file
const authRoutes = require('./routes/auth');
app.use('/auth', authRoutes);