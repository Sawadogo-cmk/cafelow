# Structure de la base de données CaféFlow

Base de données : **`cafeflow`**  
Moteur : **MySQL 8.0+**

---

## Schéma global

```
users
  ├── id (PK)
  ├── email
  ├── password_hash
  ├── role (admin / client)
  ├── name
  ├── phone
  └── created_at

categories
  ├── id (PK)
  └── name

menu
  ├── id (PK)
  ├── name
  ├── description
  ├── price
  ├── image_url (Cloudinary)
  ├── category_id (FK → categories.id)
  └── created_at

orders
  ├── id (PK)
  ├── user_id (FK → users.id)
  ├── customer_name
  ├── total
  ├── status (en_attente / en_preparation / termine)
  ├── created_at
  └── updated_at

order_items
  ├── id (PK)
  ├── order_id (FK → orders.id)
  ├── menu_id (FK → menu.id)
  ├── quantity
  └── price (prix au moment de la commande)

shop_settings
  ├── id (PK)
  ├── shop_name
  ├── address
  ├── phone
  └── updated_at
```

---

## Création des tables (SQL)

```sql
-- Table des utilisateurs
CREATE TABLE users (
    id INT AUTO_INCREMENT PRIMARY KEY,
    email VARCHAR(255) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    role ENUM('admin', 'client') DEFAULT 'client',
    name VARCHAR(255),
    phone VARCHAR(50),
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Table des catégories
CREATE TABLE categories (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL
);

-- Table du menu
CREATE TABLE menu (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price INT NOT NULL,
    image_url VARCHAR(255),
    category_id INT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (category_id) REFERENCES categories(id) ON DELETE SET NULL
);

-- Table des commandes
CREATE TABLE orders (
    id INT AUTO_INCREMENT PRIMARY KEY,
    user_id INT,
    customer_name VARCHAR(255) NOT NULL,
    total INT NOT NULL,
    status ENUM('en_attente', 'en_preparation', 'termine') DEFAULT 'en_attente',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL
);

-- Table des articles de commande
CREATE TABLE order_items (
    id INT AUTO_INCREMENT PRIMARY KEY,
    order_id INT NOT NULL,
    menu_id INT NOT NULL,
    quantity INT NOT NULL,
    price INT NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(id) ON DELETE CASCADE,
    FOREIGN KEY (menu_id) REFERENCES menu(id) ON DELETE CASCADE
);

-- Table des paramètres de la boutique
CREATE TABLE shop_settings (
    id INT AUTO_INCREMENT PRIMARY KEY,
    shop_name VARCHAR(255) DEFAULT 'CaféFlow',
    address TEXT,
    phone VARCHAR(50),
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);

-- Insertion d'une catégorie par défaut
INSERT INTO categories (name) VALUES ('Boissons'), ('Pâtisseries'), ('Plats');
```

---

## Relations (Clés étrangères)

| Table | Colonne | Référence |
| :--- | :--- | :--- |
| `menu` | `category_id` | `categories.id` |
| `orders` | `user_id` | `users.id` |
| `order_items` | `order_id` | `orders.id` |
| `order_items` | `menu_id` | `menu.id` |