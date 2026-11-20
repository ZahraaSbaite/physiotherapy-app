require('dotenv').config();
const { notFound, errorHandler } = require('./middleware/errorHandler');
const express = require('express');
const authRoutes = require('./routes/auth');
const cors = require('cors');
const helmet = require('helmet');
const morgan = require('morgan');
const connectDB = require('./config/db');
const patientRoutes = require('./routes/patients');

const app = express();

app.use(helmet());
app.use(cors());
app.use(express.json());
app.use((req, res, next) => {
    req.body ??= {};
    next();
});
app.use(morgan('dev'));

app.get('/api/health', (req, res) => {
    res.json({ status: 'ok', time: new Date().toISOString() });
});
app.use('/api/auth', authRoutes);
app.use('/api/patients', patientRoutes);
app.use(notFound);
app.use(errorHandler);

const PORT = process.env.PORT || 5000;

connectDB().then(() => {
    app.listen(PORT, () => console.log(`Server running on port ${PORT}`));
});