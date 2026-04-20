-- RestockLog seed inserts based on ItemID keys from Sheet5 (1-951).
-- Uses a temporary staging table so final insert does not read RetailItem directly.
-- This avoids MySQL error 1442 when RestockLog triggers update RetailItem.

DROP TEMPORARY TABLE IF EXISTS tmp_restock_seed;

CREATE TEMPORARY TABLE tmp_restock_seed (
    ItemID   INT NOT NULL,
    Quantity INT NOT NULL,
    Cost     DECIMAL(10,2) NOT NULL
);

INSERT INTO tmp_restock_seed (ItemID, Quantity, Cost)
SELECT
    ri.ItemID,
    CASE
        WHEN ri.ItemID BETWEEN 1 AND 6 THEN 250
        WHEN ri.ItemID BETWEEN 7 AND 52 THEN 80
        WHEN ri.ItemID BETWEEN 53 AND 112 THEN 60
        ELSE GREATEST(ri.LowStockThreshold * 2, 40)
    END AS Quantity,
    ROUND(
        (
            CASE
                WHEN ri.ItemID BETWEEN 1 AND 6 THEN 250
                WHEN ri.ItemID BETWEEN 7 AND 52 THEN 80
                WHEN ri.ItemID BETWEEN 53 AND 112 THEN 60
                ELSE GREATEST(ri.LowStockThreshold * 2, 40)
            END
        ) * ri.BuyPrice,
        2
    ) AS Cost
FROM RetailItem ri
WHERE ri.ItemID BETWEEN 1 AND 951
  AND ri.IsActive = TRUE;

INSERT INTO RestockLog (ItemID, Quantity, Cost)
SELECT ItemID, Quantity, Cost
FROM tmp_restock_seed
ORDER BY ItemID;

DROP TEMPORARY TABLE IF EXISTS tmp_restock_seed;
