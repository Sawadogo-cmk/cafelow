const mysql = require('mysql2/promise');
require('dotenv').config();

const pool = mysql.createPool({
    host: process.env.DB_HOST || 'localhost',
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'cafeflow',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0
});

pool.getConnection()
    .then(connection => {
        console.log('Connexion MySQL (cafeflow) reussie !');
        connection.release();
    })
    .catch(err => {
        console.error('Erreur MySQL :', err.message);
        console.error('Verifie que XAMPP est lance et que la base "cafeflow" existe.');
    });

module.exports = pool;