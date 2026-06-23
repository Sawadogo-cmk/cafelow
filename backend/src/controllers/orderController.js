// ==================== orderController.js ====================
const pool = require('../config/db');

// Créer une commande
const createOrder = async (req, res) => {
    const { items, total } = req.body;
    const userId = req.userId; // fourni par le middleware verifyToken

    if (!items || items.length === 0) {
        return res.status(400).json({ success: false, error: 'Le panier est vide' });
    }

    try {
        // Récupérer le nom et le téléphone du client
        const [userRows] = await pool.query(
            'SELECT name, phone FROM users WHERE id = ?',
            [userId]
        );
        const customerName = userRows[0]?.name || 'Anonyme';
        const phone = userRows[0]?.phone || '';

        const [result] = await pool.query(
            'INSERT INTO orders (items, total, customer_name, phone) VALUES (?, ?, ?, ?)',
            [JSON.stringify(items), total, customerName, phone]
        );

        res.status(201).json({
            success: true,
            message: 'Commande enregistrée avec succès !',
            orderId: result.insertId,
            customerName: customerName,
            phone: phone
        });

    } catch (error) {
        console.error('Erreur lors de la création de la commande :', error);
        res.status(500).json({ success: false, error: 'Erreur serveur' });
    }
};

// Récupérer les commandes du client connecté (historique)
const getClientOrders = async (req, res) => {
    const userId = req.userId;

    try {
        // Récupérer le nom du client
        const [userRows] = await pool.query(
            'SELECT name FROM users WHERE id = ?',
            [userId]
        );
        const customerName = userRows[0]?.name || 'Anonyme';

        // Récupérer toutes les commandes portant ce nom
        const [orders] = await pool.query(
            'SELECT * FROM orders WHERE customer_name = ? ORDER BY created_at DESC',
            [customerName]
        );

        res.json({ success: true, data: orders });
    } catch (error) {
        console.error('Erreur lors de la récupération de l\'historique :', error);
        res.status(500).json({ success: false, error: 'Erreur serveur' });
    }
};

module.exports = { createOrder, getClientOrders };