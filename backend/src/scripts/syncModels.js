require('dotenv').config();
const fs = require('fs');
const path = require('path');
const mongoose = require('mongoose');

async function main() {
    await mongoose.connect(process.env.MONGODB_URI);
    console.log('Connected to', mongoose.connection.name);

    const dir = path.join(__dirname, '..', 'models');
    for (const file of fs.readdirSync(dir)) {
        if (file.endsWith('.js')) require(path.join(dir, file));
    }

    for (const name of mongoose.modelNames()) {
        const model = mongoose.model(name);
        await model.init();
        const indexes = await model.collection.indexes();
        console.log(`${name} (${model.collection.name}): ${indexes.map((i) => i.name).join(', ')}`);
    }

    await mongoose.disconnect();
    console.log('Done');
}

main().catch((err) => {
    console.error(err.message);
    process.exit(1);
});