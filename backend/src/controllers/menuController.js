const pool = require('../config/db');
const cloudinary = require('cloudinary').v2;

// Récupérer le menu
const getMenu = async (req, res) => {
    try {
        const [rows] = await pool.query(`
            SELECT m.*, c.name as category_name 
            FROM menu m
            JOIN categories c ON m.category_id = c.id
            WHERE m.available = TRUE
            ORDER BY c.name, m.name
        `);
        res.json({ success: true, data: rows });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Ajouter un plat avec image (Cloudinary)
const createMenuItem = async (req, res) => {
    const { name, category_id, price, description } = req.body;
    
    // L'URL de l'image est dans req.file.path (Cloudinary)
    const imageUrl = req.file ? req.file.path : null;

    if (!name || !category_id || price == null) {
        return res.status(400).json({ success: false, error: 'Nom, catégorie et prix requis' });
    }

    try {
        const [result] = await pool.query(
            'INSERT INTO menu (name, category_id, price, description, image_url) VALUES (?, ?, ?, ?, ?)',
            [name, category_id, price, description || '', imageUrl]
        );
        res.status(201).json({ success: true, id: result.insertId, message: 'Plat ajouté !' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Modifier un plat
const updateMenuItem = async (req, res) => {
    const { id } = req.params;
    const { name, category_id, price, description } = req.body;
    const imageUrl = req.file ? req.file.path : null;

    if (!name || !category_id || price == null) {
        return res.status(400).json({ success: false, error: 'Nom, catégorie et prix requis' });
    }

    try {
        let query = 'UPDATE menu SET name=?, category_id=?, price=?, description=?';
        const params = [name, category_id, price, description || ''];
        
        if (imageUrl) {
            // Si une nouvelle image est uploadée, supprimer l'ancienne de Cloudinary
            const [oldItem] = await pool.query('SELECT image_url FROM menu WHERE id = ?', [id]);
            if (oldItem[0]?.image_url) {
                const publicId = oldItem[0].image_url.split('/').pop().split('.')[0];
                try {
                    await cloudinary.uploader.destroy(`cafeflow/menu/${publicId}`);
                } catch (e) {
                    console.log('Erreur suppression ancienne image:', e);
                }
            }
            query += ', image_url=?';
            params.push(imageUrl);
        }
        query += ' WHERE id=?';
        params.push(id);
        await pool.query(query, params);
        res.json({ success: true, message: 'Plat mis à jour !' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

// Supprimer (soft delete) + supprimer l'image de Cloudinary
const deleteMenuItem = async (req, res) => {
    const { id } = req.params;
    try {
        // Récupérer l'image_url pour supprimer de Cloudinary
        const [rows] = await pool.query('SELECT image_url FROM menu WHERE id = ?', [id]);
        if (rows[0]?.image_url) {
            const publicId = rows[0].image_url.split('/').pop().split('.')[0];
            try {
                await cloudinary.uploader.destroy(`cafeflow/menu/${publicId}`);
            } catch (e) {
                console.log('Erreur suppression image Cloudinary:', e);
            }
        }
        await pool.query('UPDATE menu SET available = FALSE WHERE id = ?', [id]);
        res.json({ success: true, message: 'Plat supprimé !' });
    } catch (error) {
        res.status(500).json({ success: false, error: error.message });
    }
};

module.exports = { getMenu, createMenuItem, updateMenuItem, deleteMenuItem };