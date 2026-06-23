const express = require('express');
const router = express.Router();
const orderController = require('../controllers/orderController');
const verifyToken = require('../middlewares/auth');

// Route pour passer une commande (protégée)
router.post('/', verifyToken, orderController.createOrder);

// Route pour obtenir l'historique des commandes (protégée)
router.get('/history', verifyToken, orderController.getClientOrders);

module.exports = router;