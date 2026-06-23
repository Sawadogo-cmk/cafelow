const express = require('express');
const router = express.Router();
const authController = require('../controllers/authController');

router.post('/login', authController.login);         // Connexion (client ou admin)
router.post('/register', authController.registerClient); // Inscription client

module.exports = router;