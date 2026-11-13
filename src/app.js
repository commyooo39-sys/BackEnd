require('dotenv').config();

const cors = require('cors');
const express = require('express');

const app = express();

app.use(cors());
app.use(express.json());

app.get('/', (_req, res) => {
  res.status(200).json({
    message: 'Hello World! Smart Todos API is running.',
  });
});

app.get('/health', (_req, res) => {
  res.status(200).json({ status: 'ok' });
});

module.exports = app;
