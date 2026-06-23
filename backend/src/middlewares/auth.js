const jwt = require('jsonwebtoken');

const verifyToken = (req, res, next) => {
    const token = req.headers.authorization?.split(' ')[1];
    if (!token) {
        return res.status(401).json({ success: false, error: 'Token manquant' });
    }
    try {
        const decoded = jwt.verify(token, process.env.JWT_SECRET || 'monSuperSecret');
        req.userId = decoded.userId;
        next();
    } catch (error) {
        return res.status(401).json({ success: false, error: 'Token invalide' });
    }
};

module.exports = verifyToken;