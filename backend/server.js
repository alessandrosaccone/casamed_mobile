const express = require('express');
const cors = require('cors'); // Import CORS if needed
const app = express();
const port = 3000;

// Middleware
app.use(express.json());
app.use(cors()); // Enable CORS

// Counter variable
let counter = 0;

// Root endpoint
app.get('/', (req, res) => {
  res.send('Welcome to the Counter API! Use /increment to increment and /counter to get the current count.');
});

// Endpoint to increment the counter
app.post('/increment', (req, res) => {
  counter++;
  res.json({ counter });
});

// Endpoint to get the current counter
app.get('/counter', (req, res) => {
  res.json({ counter });
});

// Start the server
app.listen(port, () => {
  console.log(`Server running at http://localhost:${port}`);
});
