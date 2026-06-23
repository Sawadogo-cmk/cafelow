const pool = require('../config/db');

// Récupérer les informations de la boutique
const getShopInfo = async (req, res) => {
    try {
        const [rows] = await pool.query('SELECT * FROM shop_settings LIMIT 1');
        if (rows.length === 0) {
            return res.status(404).json({ success: false, error: 'Aucune information trouvée' });
        }
        res.json({ success: true, data: rows[0] });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: 'Erreur serveur' });
    }
};

// Mettre à jour les informations de la boutique (admin uniquement)
const updateShopInfo = async (req, res) => {
    const { address, phone, opening_hours, lat, lng } = req.body;

    if (!address || !phone || !opening_hours || lat == null || lng == null) {
        return res.status(400).json({ success: false, error: 'Tous les champs sont requis' });
    }

    try {
        // On met à jour la première ligne (il n'y en a qu'une)
        await pool.query(
            `UPDATE shop_settings 
             SET address = ?, phone = ?, opening_hours = ?, lat = ?, lng = ? 
             WHERE id = 1`,
            [address, phone, opening_hours, lat, lng]
        );
        res.json({ success: true, message: 'Informations mises à jour' });
    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: 'Erreur serveur' });
    }
};

module.exports = { getShopInfo, updateShopInfo };