const bcrypt = require('bcrypt');
const saltRounds = 10;

// Remplacez "12345678" par le mot de passe que vous voulez
const newPassword = 'MonSuperMotDePasse123!';

bcrypt.hash(newPassword, saltRounds, function(err, hash) {
    console.log('Nouveau hash à copier :', hash);
});