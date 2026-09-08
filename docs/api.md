# Documentation des endpoints API
# API CaféFlow

## Base URL
`https://cafelow.onrender.com/api`

## Authentification
La plupart des endpoints nécessitent un token JWT dans le header `Authorization: Bearer <token>`.

---

## Endpoints publics

### POST /auth/login
Connecter un utilisateur.

**Body :**
```json
{
  "email": "admin@gmail.com",
  "password": "admin123"
}