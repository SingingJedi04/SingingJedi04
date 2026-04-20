-- RestockLog seed inserts based on ItemID keys from Sheet5 (1-951).
-- Cost is derived from RetailItem.BuyPrice so it stays consistent with pricing data.

INSERT INTO RestockLog (ItemID, Quantity, Cost)
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
  AND ri.IsActive = TRUE
ORDER BY ri.ItemID;
