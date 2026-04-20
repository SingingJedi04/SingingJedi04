-- TransactionLog seed inserts based on ItemID keys from Sheet5 (1-951).
-- VisitorID follows sheet note: "will always be 1".
-- Price/TotalCost are derived from item pricing and transaction type.
-- Data is staged first to avoid MySQL error 1442 when TransactionLog triggers update RetailItem.

DROP TEMPORARY TABLE IF EXISTS tmp_transaction_seed;

CREATE TEMPORARY TABLE tmp_transaction_seed (
    ItemID INT NOT NULL,
    VisitorID INT NOT NULL,
    TxDate DATE NOT NULL,
    TxTime TIME NOT NULL,
    TxType VARCHAR(20) NOT NULL,
    Price DECIMAL(10,2) NOT NULL,
    Quantity INT NOT NULL,
    TotalCost DECIMAL(10,2) NOT NULL
);

INSERT INTO tmp_transaction_seed (ItemID, VisitorID, TxDate, TxTime, TxType, Price, Quantity, TotalCost)
SELECT
    ri.ItemID,
    1 AS VisitorID,
    DATE_SUB(CURDATE(), INTERVAL (ri.ItemID % 28) DAY) AS TxDate,
    SEC_TO_TIME((ri.ItemID * 317) % 86400) AS TxTime,
    CASE
        WHEN ri.ItemID % 17 = 0 THEN 'Stolen'
        WHEN ri.ItemID % 13 = 0 THEN 'Damaged'
        WHEN ri.ItemID % 5 = 0 AND ri.DiscountPrice IS NOT NULL THEN 'Discount'
        ELSE 'Normal'
    END AS TxType,
    CASE
        WHEN ri.ItemID % 17 = 0 THEN 0
        WHEN ri.ItemID % 13 = 0 THEN 0
        WHEN ri.ItemID % 5 = 0 AND ri.DiscountPrice IS NOT NULL THEN ri.DiscountPrice
        ELSE ri.SellPrice
    END AS Price,
    CASE
        WHEN ri.ItemID % 17 = 0 THEN 1
        WHEN ri.ItemID % 13 = 0 THEN 2
        WHEN ri.ItemID % 5 = 0 AND ri.DiscountPrice IS NOT NULL THEN 3
        ELSE 2
    END AS Quantity,
    ROUND(
        CASE
            WHEN ri.ItemID % 17 = 0 THEN 0
            WHEN ri.ItemID % 13 = 0 THEN 0
            WHEN ri.ItemID % 5 = 0 AND ri.DiscountPrice IS NOT NULL THEN ri.DiscountPrice * 3
            ELSE ri.SellPrice * 2
        END,
        2
    ) AS TotalCost
FROM RetailItem ri
WHERE ri.ItemID BETWEEN 1 AND 951
  AND ri.IsActive = TRUE;

INSERT INTO TransactionLog (ItemID, VisitorID, Date, Time, Type, Price, Quantity, TotalCost)
SELECT
    t.ItemID,
    t.VisitorID,
    t.TxDate,
    t.TxTime,
    t.TxType,
    t.Price,
    t.Quantity,
    t.TotalCost
FROM tmp_transaction_seed t
ORDER BY t.ItemID;

DROP TEMPORARY TABLE IF EXISTS tmp_transaction_seed;
