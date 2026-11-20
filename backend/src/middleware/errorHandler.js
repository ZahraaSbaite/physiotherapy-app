function notFound(req, res) {
    res.status(404).json({ message: `Route not found: ${req.method} ${req.originalUrl}` });
}

function errorHandler(err, req, res, next) {
    if (res.headersSent) return next(err);

    // Our own errors
    if (err.status) return res.status(err.status).json({ message: err.message });

    // Mongoose validation (wrong or missing fields)
    if (err.name === 'ValidationError') {
        const errors = Object.values(err.errors).map((e) => e.message);
        return res.status(400).json({ message: errors.join(', '), errors });
    }

    // Bad ID format
    if (err.name === 'CastError') {
        return res.status(400).json({ message: `Invalid ${err.path}` });
    }

    // Duplicate (for example an email that already exists)
    if (err.code === 11000) {
        const field = Object.keys(err.keyPattern || {})[0] || 'value';
        return res.status(409).json({ message: `This ${field} already exists` });
    }

    // Broken JSON in the request body
    if (err.type === 'entity.parse.failed') {
        return res.status(400).json({ message: 'Invalid JSON' });
    }

    console.error(err);
    res.status(500).json({ message: 'Something went wrong on the server' });
}

module.exports = { notFound, errorHandler };