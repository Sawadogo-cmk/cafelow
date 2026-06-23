const bcrypt = require('bcrypt');
const jwt = require('jsonwebtoken');
const pool = require('../config/db');

// ---------- CONNEXION ----------
const login = async (req, res) => {
    const { email, password } = req.body;

    try {
        const [rows] = await pool.query('SELECT * FROM users WHERE email = ?', [email]);
        if (rows.length === 0) {
            return res.status(401).json({ success: false, error: 'Email invalide' });
        }

        const user = rows[0];
        const match = await bcrypt.compare(password, user.password_hash);
        if (!match) {
            return res.status(401).json({ success: false, error: 'Mot de passe invalide' });
        }

        const token = jwt.sign(
            { userId: user.id, role: user.role },
            process.env.JWT_SECRET || 'monSuperSecret',
            { expiresIn: '24h' }
        );

        res.json({
            success: true,
            token,
            role: user.role,
            user: { id: user.id, email: user.email, name: user.name || 'Client', phone: user.phone || '' }
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: 'Erreur serveur' });
    }
};

// ---------- INSCRIPTION CLIENT (avec téléphone) ----------
const registerClient = async (req, res) => {
    const { name, email, password, phone } = req.body;

    if (!name || !email || !password) {
        return res.status(400).json({ success: false, error: 'Tous les champs sont requis (sauf téléphone optionnel)' });
    }

    try {
        const [existing] = await pool.query('SELECT id FROM users WHERE email = ?', [email]);
        if (existing.length > 0) {
            return res.status(400).json({ success: false, error: 'Cet email est déjà utilisé' });
        }

        const hashedPassword = await bcrypt.hash(password, 10);

        const [result] = await pool.query(
            'INSERT INTO users (name, email, password_hash, role, phone) VALUES (?, ?, ?, ?, ?)',
            [name, email, hashedPassword, 'client', phone || '']
        );

        res.status(201).json({
            success: true,
            message: 'Inscription réussie ! Vous pouvez vous connecter.',
            userId: result.insertId
        });

    } catch (error) {
        console.error(error);
        res.status(500).json({ success: false, error: 'Erreur serveur' });
    }
};

module.exports = { login, registerClient };