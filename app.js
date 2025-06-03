// app.js
const express = require('express');
const app = express();
const port = 3000; // Fargate tasks typically listen on a port like 3000 or 8080

app.get('/', (req, res) => {
  console.log('Received request for /');
  res.send('Hello from Fargate! This is a simple Node.js app. Current time: ' + new Date().toLocaleString());
});

// A simple health check endpoint
app.get('/health', (req, res) => {
  res.status(200).send('OK');
});

app.listen(port, () => {
  console.log(`App listening at http://localhost:${port}`);
});

process.on('SIGINT', () => {
  console.log('SIGINT signal received. Shutting down gracefully.');
  process.exit(0);
});
process.on('SIGTERM', () => {
  console.log('SIGTERM signal received. Shutting down gracefully.');
  process.exit(0);
});