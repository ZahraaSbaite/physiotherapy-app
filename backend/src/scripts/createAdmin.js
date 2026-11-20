require('dotenv').config();
const readline = require('readline');
const mongoose = require('mongoose');
const User = require('../models/User');
const { hashPassword } = require('../utils/password');

function ask(question) {
    const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
    return new Promise((resolve) =>
        rl.question(question, (answer) => {
            rl.close();
            resolve(answer.trim());
        })
    );
}

// Typed characters are not shown on screen
function askHidden(question) {
    return new Promise((resolve) => {
        process.stdout.write(question);
        const stdin = process.stdin;
        stdin.setRawMode(true);
        stdin.resume();
        stdin.setEncoding('utf8');
        let input = '';

        const onData = (chunk) => {
            for (const ch of chunk) {
                if (ch === '\r' || ch === '\n') {
                    stdin.setRawMode(false);
                    stdin.pause();
                    stdin.removeListener('data', onData);
                    process.stdout.write('\n');
                    return resolve(input);
                }
                if (ch === '\u0003') process.exit(1); // Ctrl+C
                if (ch === '\u007f' || ch === '\b') {
                    input = input.slice(0, -1);
                    continue;
                }
                input += ch;
            }
        };
        stdin.on('data', onData);
    });
}

async function main() {
    console.log('--- Create a new admin (physiotherapist) ---');

    const name = await ask('Full name: ');
    const email = (await ask('Email: ')).toLowerCase();
    const password = await askHidden('Password (min 8 characters, hidden): ');
    const confirm = await askHidden('Repeat password: ');

    if (!name) throw new Error('Name is required');
    if (!/^\S+@\S+\.\S+$/.test(email)) throw new Error('Invalid email address');
    if (password.length < 8) throw new Error('Password must be at least 8 characters');
    if (password !== confirm) throw new Error('Passwords do not match');

    await mongoose.connect(process.env.MONGODB_URI);

    if (await User.exists({ email })) throw new Error('A user with this email already exists');

    const admin = await User.create({
        role: 'admin',
        name,
        email,
        passwordHash: await hashPassword(password),
    });

    console.log(`\nAdmin created: ${admin.name} <${admin.email}>`);
    console.log(`ID: ${admin._id}`);
    await mongoose.disconnect();
}

main().catch(async (err) => {
    console.error('\nFailed:', err.message);
    await mongoose.disconnect().catch(() => { });
    process.exit(1);
});