const express = require('express');
const router = express.Router();
const adminController = require('../controllers/adminController');
const menuController = require('../controllers/menuController');
const categoryController = require('../controllers/categoryController');
const upload = require('../middlewares/upload');
const verifyToken = require('../middlewares/auth'); // 👈 IMPORTER LE MIDDLEWARE
const shopController = require('../controllers/shopController');


// ----- Commandes -----
router.get('/orders', adminController.getAllOrders);
router.put('/orders/:id/status', adminController.updateOrderStatus);

// ----- Clients -----
router.get('/clients', adminController.getClients);

// ----- Menu -----
router.post('/menu', upload.single('image'), menuController.createMenuItem);
router.put('/menu/:id', upload.single('image'), menuController.updateMenuItem);
router.delete('/menu/:id', menuController.deleteMenuItem);

// ----- Catégories -----
router.get('/categories', categoryController.getCategories);
router.post('/categories', categoryController.createCategory);
router.delete('/categories/:id', categoryController.deleteCategory);

// ============================================================
// GESTION DU PROFIL ADMIN (protégé par verifyToken)
// ============================================================
router.get('/profile', verifyToken, adminController.getAdminProfile);
router.put('/profile', verifyToken, adminController.updateAdminProfile);

// ----- Gestion de la boutique -----
router.get('/shop', shopController.getShopInfo);
router.put('/shop', verifyToken, shopController.updateShopInfo);

module.exports = router;