const pool = require('../config/db');

// Récupérer toutes les catégories
const getCategories = async (req, res) => {
    try {
        const [rows] = await pool.query('SELECT * FROM categories ORDER BY name');
        res.json({ success: true, data: rows });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Ajouter une catégorie
const createCategory = async (req, res) => {
    const { name } = req.body;
    if (!name) return res.status(400).json({ success: false, error: 'Nom requis' });
    try {
        const [result] = await pool.query('INSERT INTO categories (name) VALUES (?)', [name]);
        res.status(201).json({ success: true, id: result.insertId, name });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Supprimer une catégorie (seulement si non utilisée)
const deleteCategory = async (req, res) => {
    const { id } = req.params;
    try {
        // Vérifier si des plats l'utilisent
        const [menuRows] = await pool.query('SELECT id FROM menu WHERE category_id = ? LIMIT 1', [id]);
        if (menuRows.length > 0) {
            return res.status(400).json({ success: false, error: 'Catégorie utilisée dans le menu' });
        }
        await pool.query('DELETE FROM categories WHERE id = ?', [id]);
        res.json({ success: true, message: 'Catégorie supprimée' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { getCategories, createCategory, deleteCategory };