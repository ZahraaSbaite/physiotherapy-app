require('dotenv').config();
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const connectDB = require('./config/db');
const { notFound, errorHandler } = require('./middleware/errorHandler');

// Import Routes
const authRoutes = require('./routes/auth');
const patientRoutes = require('./routes/patients');
const appointmentRoutes = require('./routes/appointments');
const exerciseRoutes = require('./routes/exercises');
const assignmentRoutes = require('./routes/assignments');
const broadcastRoutes = require('./routes/broadcasts'); // <-- Must match file name exactly
const channelRoutes = require('./routes/channels');     // <-- Must match file name exactly
const meRoutes = require('./routes/me');

const app = express();

// Middleware
app.use(helmet());
app.use(cors());
app.use(express.json());
app.use((req, res, next) => {
  req.body ??= {};
  next();
});
app.use(morgan('dev'));

// Health Check
app.get('/api/health', (req, res) => {
  res.json({ status: 'ok', time: new Date().toISOString() });
});

// --- ROUTE MOUNTING (MUST BE BEFORE notFound) ---
app.use('/api/auth', authRoutes);
app.use('/api/patients', patientRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/exercises', exerciseRoutes);
app.use('/api/assignments', assignmentRoutes);

// 👇 THESE ARE THE CRITICAL LINES 👇
console.log('✅ Mounting /api/broadcasts and /api/channels...'); // DEBUG LOG
app.use('/api/broadcasts', broadcastRoutes);
app.use('/api/channels', channelRoutes);

app.use('/api/me', meRoutes);

// Error Handling (MUST BE LAST)
app.use(notFound);
app.use(errorHandler);

// Start Server
const PORT = process.env.PORT || 5000;
connectDB().then(() => {
  app.listen(PORT, () => console.log(`🚀 Server running on port ${PORT}`));
});