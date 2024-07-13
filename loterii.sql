CREATE TABLE IF NOT EXISTS `lottery_tickets` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `source` int(11) NOT NULL,
    `identifier` varchar(50) NOT NULL,
    PRIMARY KEY (`id`)
);

CREATE TABLE IF NOT EXISTS `lottery_winners` (
    `id` int(11) NOT NULL AUTO_INCREMENT,
    `identifier` varchar(50) NOT NULL,
    `prize` int(11) NOT NULL,
    PRIMARY KEY (`id`)
);
