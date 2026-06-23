const express = require('express');
const router = express.Router();
const menuController = require('../controllers/menuController');

// Route GET /api/menu
router.get('/', menuController.getMenu);

module.exports = router;