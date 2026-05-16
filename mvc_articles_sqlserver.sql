-- ============================================================
-- Base de données : mvc_articles
-- SGBD : Microsoft SQL Server
-- BTS SIO SLAM — Épreuve E6 — AP2
-- ============================================================

USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = 'mvc_articles')
    DROP DATABASE mvc_articles;
GO

CREATE DATABASE mvc_articles
    COLLATE French_CI_AS;
GO

USE mvc_articles;
GO

-- ============================================================
-- 1. CATEGORIE
-- ============================================================
CREATE TABLE Categorie (
    Id_Categorie    INT IDENTITY(1,1) PRIMARY KEY,
    nom_cat         NVARCHAR(100)   NOT NULL,
    description     NVARCHAR(255)   NULL,
    nb_articles     INT             NOT NULL DEFAULT 0
);
GO

-- ============================================================
-- 2. ARTICLE (entité mère — association 1-N avec Categorie)
-- ============================================================
CREATE TABLE Article (
    art_id          INT IDENTITY(1,1) PRIMARY KEY,
    art_nom         NVARCHAR(100)   NOT NULL,
    art_prix        DECIMAL(10,2)   NOT NULL,
    art_poid        NVARCHAR(50)    NOT NULL,
    art_image       NVARCHAR(255)   NOT NULL DEFAULT 'default.png',
    Id_Categorie    INT             NOT NULL,
    CONSTRAINT FK_Article_Categorie FOREIGN KEY (Id_Categorie)
        REFERENCES Categorie(Id_Categorie)
);
GO

-- ============================================================
-- 3. DETAIL_ARTICLE (association 1-1 avec Article)
-- ============================================================
CREATE TABLE DetailArticle (
    art_id          INT             PRIMARY KEY,
    garantie        NVARCHAR(50)    NULL,
    stock           INT             NOT NULL DEFAULT 0,
    CONSTRAINT FK_Detail_Article FOREIGN KEY (art_id)
        REFERENCES Article(art_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 4. ARTICLE_NEUF (héritage — entité fille de Article)
-- ============================================================
CREATE TABLE ArticleNeuf (
    art_id          INT             PRIMARY KEY,
    date_entree     DATE            NOT NULL DEFAULT CAST(GETDATE() AS DATE),
    CONSTRAINT FK_Neuf_Article FOREIGN KEY (art_id)
        REFERENCES Article(art_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 5. ARTICLE_OCCASION (héritage — entité fille de Article)
-- ============================================================
CREATE TABLE ArticleOccasion (
    art_id          INT             PRIMARY KEY,
    etat            NVARCHAR(50)    NOT NULL DEFAULT 'Bon état',
    date_achat      DATE            NULL,
    CONSTRAINT FK_Occasion_Article FOREIGN KEY (art_id)
        REFERENCES Article(art_id) ON DELETE CASCADE
);
GO

-- ============================================================
-- 6. ARTICLE_ARCHIVE (table d'archivage pour trigger DELETE)
-- ============================================================
CREATE TABLE Article_Archive (
    arch_id         INT IDENTITY(1,1) PRIMARY KEY,
    art_id          INT             NOT NULL,
    art_nom         NVARCHAR(100),
    art_prix        DECIMAL(10,2),
    art_poid        NVARCHAR(50),
    Id_Categorie    INT,
    date_suppression DATETIME       NOT NULL DEFAULT GETDATE()
);
GO

-- ============================================================
-- TRIGGERS
-- ============================================================

-- TR1 : Après INSERT sur Article → incrémente nb_articles dans Categorie
CREATE TRIGGER TR_Article_NbCat_AI
ON Article
AFTER INSERT
AS
BEGIN
    UPDATE Categorie
    SET nb_articles = nb_articles + 1
    WHERE Id_Categorie IN (SELECT Id_Categorie FROM inserted);
END;
GO

-- TR2 : Après DELETE sur Article → décrémente nb_articles + archive
CREATE TRIGGER TR_Article_Archive_AD
ON Article
AFTER DELETE
AS
BEGIN
    -- Archive
    INSERT INTO Article_Archive (art_id, art_nom, art_prix, art_poid, Id_Categorie)
    SELECT art_id, art_nom, art_prix, art_poid, Id_Categorie
    FROM deleted;

    -- Décrément
    UPDATE Categorie
    SET nb_articles = nb_articles - 1
    WHERE Id_Categorie IN (SELECT Id_Categorie FROM deleted);
END;
GO

-- TR3 : Après UPDATE sur Article → ajuste nb_articles si catégorie change
CREATE TRIGGER TR_Article_NbCat_AU
ON Article
AFTER UPDATE
AS
BEGIN
    IF UPDATE(Id_Categorie)
    BEGIN
        UPDATE Categorie
        SET nb_articles = nb_articles - 1
        WHERE Id_Categorie IN (SELECT Id_Categorie FROM deleted);

        UPDATE Categorie
        SET nb_articles = nb_articles + 1
        WHERE Id_Categorie IN (SELECT Id_Categorie FROM inserted);
    END
END;
GO

-- TR4 : Avant INSERT → met art_nom en majuscules (via UPPER)
CREATE TRIGGER TR_Article_NomMaj_AI
ON Article
INSTEAD OF INSERT
AS
BEGIN
    INSERT INTO Article (art_nom, art_prix, art_poid, art_image, Id_Categorie)
    SELECT UPPER(art_nom), art_prix, art_poid, art_image, Id_Categorie
    FROM inserted;
END;
GO

-- ============================================================
-- PROCÉDURES STOCKÉES
-- ============================================================

-- PS1 : Ajouter un article (avec vérification catégorie)
CREATE PROCEDURE PS_AjouterArticle
    @p_nom          NVARCHAR(100),
    @p_prix         DECIMAL(10,2),
    @p_poid         NVARCHAR(50),
    @p_image        NVARCHAR(255),
    @p_IdCategorie  INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Categorie WHERE Id_Categorie = @p_IdCategorie)
    BEGIN
        RAISERROR('Catégorie inexistante', 16, 1);
        RETURN;
    END

    INSERT INTO Article (art_nom, art_prix, art_poid, art_image, Id_Categorie)
    VALUES (@p_nom, @p_prix, @p_poid, @p_image, @p_IdCategorie);

    -- Créer automatiquement un détail par défaut (1-1)
    INSERT INTO DetailArticle (art_id, garantie, stock)
    VALUES (SCOPE_IDENTITY(), '1 an', 0);
END;
GO

-- PS2 : Lister les articles d'une catégorie
CREATE PROCEDURE PS_ArticlesParCategorie
    @p_IdCategorie INT
AS
BEGIN
    SELECT a.art_id, a.art_nom, a.art_prix, a.art_poid,
           c.nom_cat, d.stock, d.garantie
    FROM Article a
    JOIN Categorie c ON c.Id_Categorie = a.Id_Categorie
    LEFT JOIN DetailArticle d ON d.art_id = a.art_id
    WHERE a.Id_Categorie = @p_IdCategorie
    ORDER BY a.art_nom;
END;
GO

-- PS3 : Compter les articles par catégorie
CREATE PROCEDURE PS_NbArticlesCategorie
    @p_IdCategorie  INT,
    @p_Nb           INT OUTPUT
AS
BEGIN
    SELECT @p_Nb = COUNT(*)
    FROM Article
    WHERE Id_Categorie = @p_IdCategorie;
END;
GO

-- PS4 : Supprimer un article (archive automatique via trigger)
CREATE PROCEDURE PS_SupprimerArticle
    @p_art_id INT
AS
BEGIN
    IF NOT EXISTS (SELECT 1 FROM Article WHERE art_id = @p_art_id)
    BEGIN
        RAISERROR('Article introuvable', 16, 1);
        RETURN;
    END
    DELETE FROM Article WHERE art_id = @p_art_id;
END;
GO

-- ============================================================
-- DONNÉES DE TEST
-- ============================================================
INSERT INTO Categorie (nom_cat, description) VALUES
('Électronique',    'Appareils électroniques et accessoires'),
('Téléphonie',      'Smartphones et accessoires'),
('Audio',           'Casques, enceintes et accessoires audio'),
('Informatique',    'PC, tablettes et périphériques');
GO

INSERT INTO Article (art_nom, art_prix, art_poid, art_image, Id_Categorie) VALUES
('Casque Sony WH-1000XM5',  350.00, '250g',  'casque.jpg',   3),
('iPhone 17 Pro Max',       1300.00,'200g',  'iphone.jpg',   2),
('Samsung Galaxy S25 Ultra',1500.00,'218g',  'samsung.jpg',  2),
('MacBook Air M3',           1200.00,'1.24kg','macbook.jpg',  4);
GO

-- Détails (1-1)
INSERT INTO DetailArticle (art_id, garantie, stock) VALUES
(1, '2 ans', 15),
(2, '1 an',  8),
(3, '1 an',  5),
(4, '1 an',  3);
GO

-- Héritage : articles neufs
INSERT INTO ArticleNeuf (art_id, date_entree) VALUES
(1, '2026-01-10'),
(2, '2026-02-15'),
(3, '2026-03-01'),
(4, '2026-01-20');
GO
