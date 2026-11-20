const mongoose = require('mongoose');
const HttpError = require('../utils/HttpError');

// Usage: router.get('/:id', validateId('id'), handler)
function validateId(...paramNames) {
    return (req, res, next) => {
        for (const name of paramNames) {
            if (!mongoose.isValidObjectId(req.params[name])) {
                throw new HttpError(400, `Invalid ${name}`);
            }
        }
        next();
    };
}

module.exports = validateId;