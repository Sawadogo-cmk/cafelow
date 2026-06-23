const multer = require('multer');
const { CloudinaryStorage } = require('multer-storage-cloudinary');
const cloudinary = require('cloudinary').v2;

// Stockage sur Cloudinary
const storage = new CloudinaryStorage({
    cloudinary: cloudinary,
    params: {
        folder: 'cafeflow/menu', // Dossier dans Cloudinary
        allowed_formats: ['jpg', 'jpeg', 'png', 'gif'],
        transformation: [{ width: 500, height: 500, crop: 'limit' }]
    }
});

// Filtrer les fichiers
const fileFilter = (req, file, cb) => {
    const allowedTypes = /jpeg|jpg|png|gif/;
    const ext = file.originalname.toLowerCase().match(/\.(jpeg|jpg|png|gif)$/);
    if (allowedTypes.test(file.mimetype) || ext) {
        cb(null, true);
    } else {
        cb(new Error('Format d\'image non supporté'), false);
    }
};

// Limite de taille
const upload = multer({
    storage: storage,
    fileFilter: fileFilter,
    limits: { fileSize: 5 * 1024 * 1024 } // 5MB max
});

module.exports = upload;