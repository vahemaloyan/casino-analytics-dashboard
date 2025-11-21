Create Schema casino

-- Partners (dimension)
CREATE TABLE casino.partners (
    Partner_ID Int PRIMARY KEY,
    Partner_Name Varchar(250) NOT NULL,
	Partner_Country Varchar(250) NOT NULL
);

-- Clients (dimension)
CREATE TABLE casino.clients (
    Client_ID Int PRIMARY KEY,
    Client_Age Int,
    Age_Group Varchar(250),
    Client_Gender Varchar(250),
    Client_Country Varchar(250),
    Is_Test Boolean
);

-- Providers (dimension)
CREATE TABLE casino.providers (
    Provider_ID Int PRIMARY KEY,
    Provider_Name Varchar(250) NOT NULL
);

-- Games (dimension)
CREATE TABLE casino.games (
    Game_id Int PRIMARY KEY,
    Game_name Varchar(250) NOT NULL
);

-- Product (dimension)
CREATE TABLE casino.products (
    Product_ID Int PRIMARY KEY,
    Product_Name Varchar(250) NOT NULL
);

-- Turnover / Bets (fact table)
CREATE TABLE casino.turnover (
    turnover_id SERIAL PRIMARY KEY,
    client_id INT REFERENCES casino.clients(client_id),
    partner_id INT REFERENCES casino.partners(partner_id),
	currency_id Varchar(250),
    game_id INT REFERENCES casino.games(game_id),
	provider_id INT REFERENCES casino.providers(provider_id),
	product_id INT REFERENCES casino.products(product_id),
	Is_RakeTransaction Boolean,
	Is_Calculated Boolean,
	Is_Rollbacked Boolean,
	Is_Bonus Boolean,
	Bet_Amount decimal(15,5),
	Win_Amount decimal(15,5),
	BonusBet_Amount decimal(15,5),
	BonusWin_Amount decimal(15,5),
	RakeBet_Amount decimal(15,5),
	RakeWin_Amount decimal(15,5),
	BetAmountIn_EUR decimal(15,5),
	WinAmountIn_EUR decimal(15,5),
	BonusBetAmountIn_EUR decimal(15,5),
	BonusWinAmountIn_EUR decimal(15,5),
	RakeBetAmountIn_EUR decimal(15,5),
	RakeWinAmountIn_EUR decimal(15,5)
);

SELECT t.turnover_id, t.Client_ID, p.Partner_Name, p.Partner_Country,
 t.Game_ID, g.Game_Name, t.Provider_ID, v.Provider_Name, t.Product_ID, pr.Product_Name,
 t.BetAmountIn_EUR, t.WinAmountIn_EUR, t.BonusBetAmountIn_EUR, t.BonusWinAmountIn_EUR, t.Is_Bonus
 FROM casino.turnover AS t
 JOIN casino.partners AS p ON t.Partner_ID = p.Partner_ID
 JOIN casino.games AS g ON t.Game_ID = g.Game_ID
 JOIN casino.providers AS v ON t.Provider_ID = v.Provider_ID
 JOIN casino.products AS pr ON t.Product_ID = pr.Product_ID;

-- Defining Key Metrics (Turnover, GGR, NGR)

-- By Partner
 SELECT p.Partner_ID, p.Partner_Name, p.Partner_Country,
       SUM(t.BetAmountIn_EUR) AS Total_Turnover_EUR,
       SUM(t.BetAmountIn_EUR - t.WinAmountIn_EUR - t.BonusWinAmountIn_EUR) AS GGR_EUR,
       SUM((t.BetAmountIn_EUR - t.BonusBetAmountIn_EUR) - (t.WinAmountIn_EUR + t.BonusWinAmountIn_EUR)) AS NGR_EUR
FROM casino.turnover AS t
JOIN casino.partners AS p ON t.Partner_ID = p.Partner_ID
GROUP BY p.Partner_ID, p.Partner_Name, p.Partner_Country
ORDER BY Total_Turnover_EUR DESC;

-- By Client
SELECT c.Client_ID, c.Client_Country, c.Age_Group, c.Client_Gender,
    SUM(t.BetAmountIn_EUR) AS Total_Turnover_EUR,
    SUM(t.BetAmountIn_EUR - t.WinAmountIn_EUR - t.BonusWinAmountIn_EUR) AS GGR_EUR,
    SUM((t.BetAmountIn_EUR - t.BonusBetAmountIn_EUR) - (t.WinAmountIn_EUR + t.BonusWinAmountIn_EUR)) AS NGR_EUR
FROM casino.turnover AS t
JOIN casino.clients AS c ON t.Client_ID = c.Client_ID
GROUP BY c.Client_ID, c.Client_Country, c.Age_Group, c.Client_Gender
ORDER BY Total_Turnover_EUR DESC;

-- By Games
SELECT g.Game_ID, g.Game_Name,
    SUM(t.BetAmountIn_EUR) AS Total_Turnover_EUR,
    SUM(t.BetAmountIn_EUR - t.WinAmountIn_EUR - t.BonusWinAmountIn_EUR) AS GGR_EUR,
    SUM((t.BetAmountIn_EUR - t.BonusBetAmountIn_EUR) - (t.WinAmountIn_EUR + t.BonusWinAmountIn_EUR)) AS NGR_EUR
FROM casino.turnover AS t
JOIN casino.games AS g ON t.Game_ID = g.Game_ID
GROUP BY g.Game_ID, g.Game_Name
ORDER BY Total_Turnover_EUR DESC;

-- By Provider
SELECT v.Provider_ID, v.Provider_Name,
    SUM(t.BetAmountIn_EUR) AS Total_Turnover_EUR,
    SUM(t.BetAmountIn_EUR - t.WinAmountIn_EUR - t.BonusWinAmountIn_EUR) AS GGR_EUR,
    SUM((t.BetAmountIn_EUR - t.BonusBetAmountIn_EUR) - (t.WinAmountIn_EUR + t.BonusWinAmountIn_EUR)) AS NGR_EUR
FROM casino.turnover AS t
JOIN casino.providers AS v ON t.Provider_ID = v.Provider_ID
GROUP BY v.Provider_ID, v.Provider_Name
ORDER BY Total_Turnover_EUR DESC;

-- By Product
SELECT pr.Product_ID, pr.Product_Name,
    SUM(t.BetAmountIn_EUR) AS Total_Turnover_EUR,
    SUM(t.BetAmountIn_EUR - t.WinAmountIn_EUR - t.BonusWinAmountIn_EUR) AS GGR_EUR,
    SUM((t.BetAmountIn_EUR - t.BonusBetAmountIn_EUR) - (t.WinAmountIn_EUR + t.BonusWinAmountIn_EUR)) AS NGR_EUR
FROM casino.turnover AS t
JOIN casino.products AS pr ON t.Product_ID = pr.Product_ID
GROUP BY pr.Product_ID, pr.Product_Name
ORDER BY Total_Turnover_EUR DESC;

-- Partner-level metrics
CREATE OR REPLACE VIEW casino.metrics_by_partner AS
SELECT 
    'Partner' AS Dimension_Type,
    p.Partner_ID AS Dimension_ID,
    p.Partner_Name AS Dimension_Label,
    p.Partner_Country AS Extra_Info,
    SUM(t.BetAmountIn_EUR) AS Total_Turnover_EUR,
    SUM(t.BetAmountIn_EUR - t.WinAmountIn_EUR - t.BonusWinAmountIn_EUR) AS GGR_EUR,
    SUM((t.BetAmountIn_EUR - t.BonusBetAmountIn_EUR) - (t.WinAmountIn_EUR + t.BonusWinAmountIn_EUR)) AS NGR_EUR
FROM casino.turnover AS t
JOIN casino.partners AS p ON t.Partner_ID = p.Partner_ID
GROUP BY p.Partner_ID, p.Partner_Name, p.Partner_Country;

-- Provider-level metrics
CREATE OR REPLACE VIEW casino.metrics_by_provider AS
SELECT 
    'Provider' AS Dimension_Type,
    v.Provider_ID AS Dimension_ID,
    v.Provider_Name AS Dimension_Label,
    NULL::varchar AS Extra_Info,
    SUM(t.BetAmountIn_EUR) AS Total_Turnover_EUR,
    SUM(t.BetAmountIn_EUR - t.WinAmountIn_EUR - t.BonusWinAmountIn_EUR) AS GGR_EUR,
    SUM((t.BetAmountIn_EUR - t.BonusBetAmountIn_EUR) - (t.WinAmountIn_EUR + t.BonusWinAmountIn_EUR)) AS NGR_EUR
FROM casino.turnover AS t
JOIN casino.providers AS v ON t.Provider_ID = v.Provider_ID
GROUP BY v.Provider_ID, v.Provider_Name;

-- Product-level metrics
CREATE OR REPLACE VIEW casino.metrics_by_product AS
SELECT 
    'Product' AS Dimension_Type,
    pr.Product_ID AS Dimension_ID,
    pr.Product_Name AS Dimension_Label,
    NULL::varchar AS Extra_Info,
    SUM(t.BetAmountIn_EUR) AS Total_Turnover_EUR,
    SUM(t.BetAmountIn_EUR - t.WinAmountIn_EUR - t.BonusWinAmountIn_EUR) AS GGR_EUR,
    SUM((t.BetAmountIn_EUR - t.BonusBetAmountIn_EUR) - (t.WinAmountIn_EUR + t.BonusWinAmountIn_EUR)) AS NGR_EUR
FROM casino.turnover AS t
JOIN casino.products AS pr ON t.Product_ID = pr.Product_ID
GROUP BY pr.Product_ID, pr.Product_Name;

-- Game-level metrics
CREATE OR REPLACE VIEW casino.metrics_by_game AS
SELECT 
    'Game' AS Dimension_Type,
    g.Game_ID AS Dimension_ID,
    g.Game_Name AS Dimension_Label,
    NULL::varchar AS Extra_Info,
    SUM(t.BetAmountIn_EUR) AS Total_Turnover_EUR,
    SUM(t.BetAmountIn_EUR - t.WinAmountIn_EUR - t.BonusWinAmountIn_EUR) AS GGR_EUR,
    SUM((t.BetAmountIn_EUR - t.BonusBetAmountIn_EUR) - (t.WinAmountIn_EUR + t.BonusWinAmountIn_EUR)) AS NGR_EUR
FROM casino.turnover AS t
JOIN casino.games AS g ON t.Game_ID = g.Game_ID
GROUP BY g.Game_ID, g.Game_Name;

-- Client-level metrics
CREATE OR REPLACE VIEW casino.metrics_by_client AS
SELECT 
    'Client' AS Dimension_Type,
    c.Client_ID AS Dimension_ID,
    CONCAT('Client_', c.Client_ID::varchar) AS Dimension_Label,
    CONCAT(
        'Country: ', COALESCE(c.Client_Country, 'Unknown'),
        ' | Age Group: ', COALESCE(c.Age_Group, 'Unknown'),
        ' | Gender: ', COALESCE(c.Client_Gender, 'Unknown')
    ) AS Extra_Info,
    SUM(t.BetAmountIn_EUR) AS Total_Turnover_EUR,
    SUM(t.BetAmountIn_EUR - t.WinAmountIn_EUR - t.BonusWinAmountIn_EUR) AS GGR_EUR,
    SUM((t.BetAmountIn_EUR - t.BonusBetAmountIn_EUR) - (t.WinAmountIn_EUR + t.BonusWinAmountIn_EUR)) AS NGR_EUR
FROM casino.turnover AS t
JOIN casino.clients AS c ON t.Client_ID = c.Client_ID
GROUP BY c.Client_ID, c.Client_Country, c.Age_Group, c.Client_Gender;

-- Unified Master View for Power BI
CREATE OR REPLACE VIEW casino.all_metrics AS
SELECT * FROM casino.metrics_by_partner
UNION ALL
SELECT * FROM casino.metrics_by_provider
UNION ALL
SELECT * FROM casino.metrics_by_product
UNION ALL
SELECT * FROM casino.metrics_by_game
UNION ALL
SELECT * FROM casino.metrics_by_client;

SELECT 
    Dimension_Type,
    Dimension_Label,
    COALESCE(Extra_Info, '') AS Extra_Info,
    ROUND(Total_Turnover_EUR, 2) AS Total_Turnover_EUR,
    ROUND(GGR_EUR, 2) AS GGR_EUR,
    ROUND(NGR_EUR, 2) AS NGR_EUR
FROM casino.all_metrics
ORDER BY Dimension_Type, Total_Turnover_EUR DESC;