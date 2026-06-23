const pool = require('../config/db');

// Récupérer toutes les commandes + chiffre d'affaires des commandes terminées
const getAllOrders = async (req, res) => {
    try {
        const [rows] = await pool.query(
            'SELECT * FROM orders ORDER BY created_at DESC'
        );
        // Calcul du chiffre d'affaires des commandes terminées
        const [revenueResult] = await pool.query(
            'SELECT SUM(total) AS total_revenue FROM orders WHERE status = "termine"'
        );
        const totalRevenueCompleted = revenueResult[0]?.total_revenue || 0;
        
        res.json({ 
            success: true, 
            data: rows,
            totalRevenueCompleted: totalRevenueCompleted
        });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: 'Erreur serveur' });
    }
};

// Mettre à jour le statut d'une commande
const updateOrderStatus = async (req, res) => {
    const { id } = req.params;
    const { status } = req.body;

    const validStatus = ['en_attente', 'en_preparation', 'termine'];
    if (!validStatus.includes(status)) {
        return res.status(400).json({ success: false, error: 'Statut invalide' });
    }

    try {
        await pool.query(
            'UPDATE orders SET status = ? WHERE id = ?',
            [status, id]
        );
        res.json({ success: true, message: 'Statut mis à jour' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: 'Erreur serveur' });
    }
};

// Récupérer tous les clients
const getClients = async (req, res) => {
    try {
        const [rows] = await pool.query(
            'SELECT id, name, email, created_at FROM users WHERE role = "client" ORDER BY created_at DESC'
        );
        res.json({ success: true, data: rows });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: 'Erreur serveur' });
    }
};

// ----- GESTION DU PROFIL ADMIN -----

// Récupérer le profil de l'admin connecté
const getAdminProfile = async (req, res) => {
    const userId = req.userId;
    try {
        const [rows] = await pool.query(
            'SELECT id, name, email, phone FROM users WHERE id = ?',
            [userId]
        );
        if (rows.length === 0) {
            return res.status(404).json({ success: false, error: 'Admin non trouvé' });
        }
        res.json({ success: true, data: rows[0] });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: 'Erreur serveur' });
    }
};

// Mettre à jour le profil de l'admin
const updateAdminProfile = async (req, res) => {
    const userId = req.userId;
    const { name, email, phone } = req.body;

    if (!name || !email) {
        return res.status(400).json({ success: false, error: 'Nom et email sont requis' });
    }

    try {
        await pool.query(
            'UPDATE users SET name = ?, email = ?, phone = ? WHERE id = ?',
            [name, email, phone || '', userId]
        );
        res.json({ success: true, message: 'Profil mis à jour avec succès' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: 'Erreur serveur' });
    }
};

module.exports = { 
    getAllOrders, 
    updateOrderStatus, 
    getClients,
    getAdminProfile,
    updateAdminProfile
};