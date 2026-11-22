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
const broadcastRoutes = require('./routes/broadcasts');
const channelRoutes = require('./routes/channels');
const meRoutes = require('./routes/me');

// 👇 ADD RATE LIMITER IMPORT 👇
const rateLimit = require('express-rate-limit');

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

// 👇 CONFIGURE LOGIN RATE LIMITER 👇
const loginLimiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 5, // Limit each IP to 5 login requests per windowMs
  message: {
    error: 'Too many login attempts from this IP, please try again after 15 minutes',
  },
  standardHeaders: 'draft-7',
  legacyHeaders: false,
});

// --- ROUTE MOUNTING (MUST BE BEFORE notFound) ---
// 👇 APPLY LIMITER TO LOGIN ROUTE ONLY 👇
app.use('/api/auth/login', loginLimiter);

app.use('/api/auth', authRoutes);
app.use('/api/patients', patientRoutes);
app.use('/api/appointments', appointmentRoutes);
app.use('/api/exercises', exerciseRoutes);
app.use('/api/assignments', assignmentRoutes);
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