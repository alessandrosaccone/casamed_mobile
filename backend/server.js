const express = require('express');
const cors = require('cors'); // Allow CORS
const app = express();
const port = 3000;

app.use(cors()); // Use CORS middleware
app.use(express.json()); // Parse JSON requests

app.get('/api', (req, res) => {
    res.json({ message: 'Hello from Node.js!' });
});

app.listen(port, () => {
    console.log(`Server is running at http://localhost:${port}`);
});
