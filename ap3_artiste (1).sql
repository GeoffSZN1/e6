-- phpMyAdmin SQL Dump
-- version 5.2.2
-- https://www.phpmyadmin.net/
--
-- Hôte : localhost:3306
-- Généré le : jeu. 28 mai 2026 à 07:40
-- Version du serveur : 8.4.3
-- Version de PHP : 8.3.16

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Base de données : `ap3_artiste`
--

DELIMITER $$
--
-- Procédures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `PS_AjouterArtiste` (IN `p_nom_art` VARCHAR(100), IN `p_description` TEXT, IN `p_IdCategorie` INT)   BEGIN
    DECLARE v_nb_cat INT;

    -- Vérifier que la catégorie existe
    SELECT COUNT(*)
    INTO v_nb_cat
    FROM Categorie
    WHERE Id_Categorie = p_IdCategorie;

    IF v_nb_cat = 0 THEN
        SIGNAL SQLSTATE '45000'
            SET MESSAGE_TEXT = 'Categorie inexistante';
    ELSE
        INSERT INTO Artiste(nom_art, description, Id_Categorie, valide)
        VALUES (UPPER(p_nom_art), p_description, p_IdCategorie, 0);
    END IF;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `PS_ArtistesParCategorie` (IN `p_IdCategorie` INT)   BEGIN
    SELECT a.Id_Artiste,
           a.nom_art,
           a.description,
           c.nom_cat
    FROM Artiste a
    JOIN Categorie c ON c.Id_Categorie = a.Id_Categorie
    WHERE a.Id_Categorie = p_IdCategorie
      AND a.valide = 1
    ORDER BY a.nom_art;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `PS_DernieresConsultations` (IN `p_UserId` INT, IN `p_Limite` INT)   BEGIN
    SELECT h.Id_Historique,
           h.valeur,
           h.date_creation
    FROM Historique h
    WHERE h.user_id = p_UserId
    ORDER BY h.date_creation DESC
    LIMIT p_Limite;
END$$

CREATE DEFINER=`root`@`localhost` PROCEDURE `PS_NbArtistesCategorie` (IN `p_IdCategorie` INT, OUT `p_Nb` INT)   BEGIN
    SELECT COUNT(*)
    INTO p_Nb
    FROM Artiste
    WHERE Id_Categorie = p_IdCategorie
      AND valide = 1;
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `admin`
--

CREATE TABLE `admin` (
  `Id_Admin` int NOT NULL,
  `pseudo` varchar(50) DEFAULT NULL,
  `mot_de_passe` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `admin`
--

INSERT INTO `admin` (`Id_Admin`, `pseudo`, `mot_de_passe`) VALUES
(4, 'admin', '$2y$10$rh76pAaKk3GfY7p1G6BfCeVyGQqFxXpnsZuld/mGW92UMM11R/Yza');

-- --------------------------------------------------------

--
-- Structure de la table `artiste`
--

CREATE TABLE `artiste` (
  `Id_Artiste` int NOT NULL,
  `nom_art` varchar(50) DEFAULT NULL,
  `description` varchar(50) DEFAULT NULL,
  `Id_Categorie` int NOT NULL,
  `valide` tinyint(1) NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `artiste`
--

INSERT INTO `artiste` (`Id_Artiste`, `nom_art`, `description`, `Id_Categorie`, `valide`) VALUES
(1, 'Les Éclats Sonores', 'Groupe de rock indépendant français', 1, 1),
(2, 'Marie Saxophone', 'Saxophoniste jazz professionnelle', 2, 1),
(3, 'Digital Waves', 'Producteur de musique électronique', 3, 1),
(4, 'Orchestre Symphonique', 'Formation classique renommée', 4, 1),
(5, 'Julien Portraits', 'Spécialiste en portraits artistiques', 5, 1),
(6, 'Nature Vision', 'Photographe de paysages naturels', 6, 1),
(7, 'Street Stories', 'Photographie de rue urbaine', 7, 1),
(8, 'Fashion Focus', 'Photographe mode et beauté', 8, 1),
(9, 'Blues Brothers Duo', 'Duo de blues traditionnel', 2, 1),
(10, 'Electronic Dreams', 'Artiste ambient et downtempo', 3, 1),
(13, 'La Squadra', 'La rue', 7, 1),
(16, 'Sio', 'AP3\r\n', 3, 1),
(17, 'hasared', 'fefe\r\n', 7, 0);

--
-- Déclencheurs `artiste`
--
DELIMITER $$
CREATE TRIGGER `TR_Artiste_Archive_AD` AFTER DELETE ON `artiste` FOR EACH ROW BEGIN
    INSERT INTO Artiste_Archive
        (Id_Artiste, nom_art, description, Id_Categorie, valide, date_suppression)
    VALUES
        (OLD.Id_Artiste, OLD.nom_art, OLD.description, OLD.Id_Categorie, OLD.valide, NOW());
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Artiste_NbCat_AD` AFTER DELETE ON `artiste` FOR EACH ROW BEGIN
    UPDATE Categorie
    SET nb_artistes = nb_artistes - 1
    WHERE Id_Categorie = OLD.Id_Categorie;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Artiste_NbCat_AI` AFTER INSERT ON `artiste` FOR EACH ROW BEGIN
    UPDATE Categorie
    SET nb_artistes = nb_artistes + 1
    WHERE Id_Categorie = NEW.Id_Categorie;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Artiste_NbCat_AU` AFTER UPDATE ON `artiste` FOR EACH ROW BEGIN
    IF NEW.Id_Categorie <> OLD.Id_Categorie THEN
        UPDATE Categorie
        SET nb_artistes = nb_artistes - 1
        WHERE Id_Categorie = OLD.Id_Categorie;

        UPDATE Categorie
        SET nb_artistes = nb_artistes + 1
        WHERE Id_Categorie = NEW.Id_Categorie;
    END IF;
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Artiste_NomMaj_BI` BEFORE INSERT ON `artiste` FOR EACH ROW BEGIN
    SET NEW.nom_art = UPPER(NEW.nom_art);
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `TR_Artiste_NomMaj_BU` BEFORE UPDATE ON `artiste` FOR EACH ROW BEGIN
    SET NEW.nom_art = UPPER(NEW.nom_art);
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Structure de la table `artiste_archive`
--

CREATE TABLE `artiste_archive` (
  `Id_Artiste` int DEFAULT NULL,
  `nom_art` varchar(100) DEFAULT NULL,
  `description` text,
  `Id_Categorie` int DEFAULT NULL,
  `valide` tinyint(1) DEFAULT NULL,
  `date_suppression` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `artiste_archive`
--

INSERT INTO `artiste_archive` (`Id_Artiste`, `nom_art`, `description`, `Id_Categorie`, `valide`, `date_suppression`) VALUES
(18, 'GEOFF', 'gfgrgr', 1, 0, '2025-12-11 15:25:40');

-- --------------------------------------------------------

--
-- Structure de la table `categorie`
--

CREATE TABLE `categorie` (
  `Id_Categorie` int NOT NULL,
  `nom_cat` varchar(50) DEFAULT NULL,
  `nb_artistes` int NOT NULL DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `categorie`
--

INSERT INTO `categorie` (`Id_Categorie`, `nom_cat`, `nb_artistes`) VALUES
(1, 'Rock', 0),
(2, 'Jazz', 0),
(3, 'Électronique', 0),
(4, 'Classique', 0),
(5, 'Portrait', 0),
(6, 'Paysage', 0),
(7, 'Street', 0),
(8, 'Mode', 0);

-- --------------------------------------------------------

--
-- Structure de la table `consulter`
--

CREATE TABLE `consulter` (
  `Id_Client` int NOT NULL,
  `Id_Artiste` int NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `consulter`
--

INSERT INTO `consulter` (`Id_Client`, `Id_Artiste`) VALUES
(1, 1),
(2, 1),
(7, 1),
(1, 2),
(5, 2),
(2, 3),
(7, 3),
(5, 4),
(3, 5),
(4, 5),
(8, 5),
(3, 6),
(6, 6),
(8, 6),
(3, 7),
(6, 7),
(8, 7),
(4, 8),
(8, 8),
(1, 9),
(5, 9),
(2, 10),
(7, 10);

-- --------------------------------------------------------

--
-- Structure de la table `historique`
--

CREATE TABLE `historique` (
  `Id_Historique` int NOT NULL,
  `user_id` int DEFAULT NULL,
  `valeur` varchar(50) DEFAULT NULL,
  `date_creation` datetime DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `historique`
--

INSERT INTO `historique` (`Id_Historique`, `user_id`, `valeur`, `date_creation`) VALUES
(1, 5, 'connexion', '2024-02-21 07:38:00'),
(2, 1, 'recherche', '2024-03-26 21:56:00'),
(3, 5, 'profil_modifié', '2024-04-24 17:22:00'),
(4, 7, 'recherche', '2024-02-02 10:44:00'),
(5, 5, 'connexion', '2024-09-06 13:52:00'),
(6, 1, 'recherche', '2024-12-10 23:54:00'),
(7, 4, 'recherche', '2024-11-10 08:43:00'),
(8, 3, 'connexion', '2024-03-15 20:17:00'),
(9, 7, 'connexion', '2024-07-21 23:57:00'),
(10, 3, 'favori_ajouté', '2024-03-26 00:46:00'),
(11, 7, 'connexion', '2024-05-26 23:09:00'),
(12, 6, 'recherche', '2024-10-03 01:58:00'),
(13, 4, 'consultation_artiste', '2024-05-25 07:36:00'),
(14, 2, 'recherche', '2024-08-03 07:56:00'),
(15, 7, 'favori_ajouté', '2024-12-21 01:29:00'),
(16, 4, 'connexion', '2024-06-18 02:48:00'),
(17, 8, 'favori_ajouté', '2024-08-12 18:03:00'),
(18, 6, 'favori_ajouté', '2024-05-22 02:49:00'),
(19, 8, 'consultation_artiste', '2024-05-12 22:07:00'),
(20, 7, 'favori_ajouté', '2024-01-02 15:14:00'),
(21, 9, 'consult_artiste_2', '2025-12-09 22:04:59'),
(22, 9, 'consult_artiste_2', '2025-12-10 08:10:19'),
(23, 9, 'consult_artiste_17', '2025-12-10 08:22:30'),
(24, 9, 'consult_artiste_17', '2025-12-10 08:22:43');

-- --------------------------------------------------------

--
-- Structure de la table `musicien`
--

CREATE TABLE `musicien` (
  `Id_Artiste` int NOT NULL,
  `type_mus` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `musicien`
--

INSERT INTO `musicien` (`Id_Artiste`, `type_mus`) VALUES
(1, 'Groupe rock alternatif'),
(2, 'Soliste jazz'),
(3, 'DJ/Producteur'),
(4, 'Orchestre symphonique'),
(9, 'Duo blues'),
(10, 'Artiste électronique');

-- --------------------------------------------------------

--
-- Structure de la table `photographe`
--

CREATE TABLE `photographe` (
  `Id_Artiste` int NOT NULL,
  `type_photo` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `photographe`
--

INSERT INTO `photographe` (`Id_Artiste`, `type_photo`) VALUES
(5, 'Portrait studio'),
(6, 'Nature/Paysage'),
(7, 'Street photography'),
(8, 'Mode/Commercial');

-- --------------------------------------------------------

--
-- Structure de la table `users`
--

CREATE TABLE `users` (
  `Id_Client` int NOT NULL,
  `Pseudo` varchar(50) DEFAULT NULL,
  `e_mail` varchar(50) DEFAULT NULL,
  `mot_de_passe` varchar(255) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci DEFAULT NULL,
  `nombre_consultations` int DEFAULT '0'
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

--
-- Déchargement des données de la table `users`
--

INSERT INTO `users` (`Id_Client`, `Pseudo`, `e_mail`, `mot_de_passe`, `nombre_consultations`) VALUES
(1, 'MusiquePassion', 'marie.dubois@email.com', 'pass123', 0),
(2, 'VinylCollector', 'jean.martin@email.com', 'secure456', 0),
(3, 'ArtLover', 'sophie.bernard@email.com', 'mypass789', 0),
(4, 'PhotoFan', 'pierre.durand@email.com', 'photo2023', 0),
(5, 'MélomaneXX', 'alice.rousseau@email.com', 'music4ever', 0),
(6, 'CreativeEye', 'thomas.petit@email.com', 'creative99', 0),
(7, 'SoundHunter', 'emma.garcia@email.com', 'sound123', 0),
(8, 'VisualArt', 'lucas.robert@email.com', 'visual456', 0),
(9, 'Geoff', 'geoffcrerar6@gmail.com', '$2y$10$JmSAA/maxS.InLniXUogbeOaZXYCmJ3JlwmHBhz9.Ie.NQeidiJRG', 0),
(10, 'testapi', 'testapi@example.com', '$2y$10$wY3BoN5SN1Kss4OXbmWxmO72ay4O4V9zJS8UoSbGe/16dA5mtmr8O', 0);

--
-- Index pour les tables déchargées
--

--
-- Index pour la table `admin`
--
ALTER TABLE `admin`
  ADD PRIMARY KEY (`Id_Admin`);

--
-- Index pour la table `artiste`
--
ALTER TABLE `artiste`
  ADD PRIMARY KEY (`Id_Artiste`),
  ADD KEY `Id_Categorie` (`Id_Categorie`);

--
-- Index pour la table `categorie`
--
ALTER TABLE `categorie`
  ADD PRIMARY KEY (`Id_Categorie`);

--
-- Index pour la table `consulter`
--
ALTER TABLE `consulter`
  ADD PRIMARY KEY (`Id_Client`,`Id_Artiste`),
  ADD KEY `Id_Artiste` (`Id_Artiste`);

--
-- Index pour la table `historique`
--
ALTER TABLE `historique`
  ADD PRIMARY KEY (`Id_Historique`);

--
-- Index pour la table `musicien`
--
ALTER TABLE `musicien`
  ADD PRIMARY KEY (`Id_Artiste`);

--
-- Index pour la table `photographe`
--
ALTER TABLE `photographe`
  ADD PRIMARY KEY (`Id_Artiste`);

--
-- Index pour la table `users`
--
ALTER TABLE `users`
  ADD PRIMARY KEY (`Id_Client`);

--
-- AUTO_INCREMENT pour les tables déchargées
--

--
-- AUTO_INCREMENT pour la table `admin`
--
ALTER TABLE `admin`
  MODIFY `Id_Admin` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=5;

--
-- AUTO_INCREMENT pour la table `artiste`
--
ALTER TABLE `artiste`
  MODIFY `Id_Artiste` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=19;

--
-- AUTO_INCREMENT pour la table `categorie`
--
ALTER TABLE `categorie`
  MODIFY `Id_Categorie` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=9;

--
-- AUTO_INCREMENT pour la table `historique`
--
ALTER TABLE `historique`
  MODIFY `Id_Historique` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=25;

--
-- AUTO_INCREMENT pour la table `users`
--
ALTER TABLE `users`
  MODIFY `Id_Client` int NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=11;

--
-- Contraintes pour les tables déchargées
--

--
-- Contraintes pour la table `artiste`
--
ALTER TABLE `artiste`
  ADD CONSTRAINT `artiste_ibfk_1` FOREIGN KEY (`Id_Categorie`) REFERENCES `categorie` (`Id_Categorie`);

--
-- Contraintes pour la table `consulter`
--
ALTER TABLE `consulter`
  ADD CONSTRAINT `consulter_ibfk_1` FOREIGN KEY (`Id_Client`) REFERENCES `users` (`Id_Client`),
  ADD CONSTRAINT `consulter_ibfk_2` FOREIGN KEY (`Id_Artiste`) REFERENCES `artiste` (`Id_Artiste`);

--
-- Contraintes pour la table `musicien`
--
ALTER TABLE `musicien`
  ADD CONSTRAINT `musicien_ibfk_1` FOREIGN KEY (`Id_Artiste`) REFERENCES `artiste` (`Id_Artiste`);

--
-- Contraintes pour la table `photographe`
--
ALTER TABLE `photographe`
  ADD CONSTRAINT `photographe_ibfk_1` FOREIGN KEY (`Id_Artiste`) REFERENCES `artiste` (`Id_Artiste`);
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
