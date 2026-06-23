const express = require('express');
const router = express.Router();
const shopController = require('../controllers/shopController');

// Route publique pour récupérer les infos de la boutique
router.get('/public', shopController.getShopInfo);

module.exports = router;