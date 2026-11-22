const HttpError = require('./HttpError');

const STATUSES = ['unpaid', 'partial', 'paid'];
const METHODS = ['cash', 'card', 'transfer', 'other'];

// '' and null mean "clear this optional field"
const blank = (v) => v === '' || v === null || v === undefined;

function money(value, field) {
    if (blank(value)) return undefined;
    const n = Number(value);
    if (!Number.isFinite(n) || n < 0) throw new HttpError(400, `${field} must be a number of 0 or more`);
    return n;
}

// Builds the payment object of an appointment from the current one (if any)
// and the fields the app sent. Returns undefined to clear the payment.
function buildPayment(existing, input, defaultCurrency) {
    if (input === null) return undefined;
    if (typeof input !== 'object' || Array.isArray(input)) {
        throw new HttpError(400, 'payment must be an object');
    }

    const p = existing ? { ...(existing.toObject ? existing.toObject() : existing) } : {};

    if (input.amount !== undefined) p.amount = money(input.amount, 'amount');
    if (input.paidAmount !== undefined) p.paidAmount = money(input.paidAmount, 'paidAmount');
    if (input.currency !== undefined) p.currency = blank(input.currency) ? undefined : String(input.currency).trim().toUpperCase();
    if (input.status !== undefined) p.status = input.status;
    if (input.method !== undefined) p.method = blank(input.method) ? undefined : input.method;
    if (input.note !== undefined) p.note = blank(input.note) ? undefined : String(input.note).trim();
    if (input.paidAt !== undefined) {
        p.paidAt = blank(input.paidAt) ? undefined : new Date(input.paidAt);
        if (p.paidAt && Number.isNaN(p.paidAt.getTime())) throw new HttpError(400, 'paidAt must be a valid date');
    }

    p.status = p.status || 'unpaid';
    if (!STATUSES.includes(p.status)) throw new HttpError(400, `payment status must be one of: ${STATUSES.join(', ')}`);
    if (p.method !== undefined && !METHODS.includes(p.method)) {
        throw new HttpError(400, `payment method must be one of: ${METHODS.join(', ')}`);
    }
    if (!p.currency) p.currency = defaultCurrency || 'USD';

    if (p.status === 'paid') {
        if (p.amount !== undefined) p.paidAmount = p.amount;
        p.paidAt = p.paidAt || new Date();
    } else if (p.status === 'unpaid') {
        p.paidAmount = 0;
        p.paidAt = undefined;
    } else {
        const ok = p.amount !== undefined && p.paidAmount > 0 && p.paidAmount < p.amount;
        if (!ok) {
            throw new HttpError(400, 'A partial payment needs an amount, and a paid amount above 0 and below it');
        }
        p.paidAt = p.paidAt || new Date();
    }

    return p;
}

module.exports = { buildPayment };
