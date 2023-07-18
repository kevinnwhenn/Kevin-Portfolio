### Display customer return rates based off of their sales
#### Include salesperson assigned to customer
--NOTE: table names and columns have been modified

```sql
SELECT
    Returns.Year,
    Returns.Month,
    MAX(Returns.Date) as Date,
    Returns.Customer,
    Returns.Salesperson,
    SUM(CASE WHEN Returns.type = 'Invoice' THEN Returns.MerchValue ELSE 0 END) AS TotalMerchandiseValue,
    SUM(CASE WHEN Returns.type = 'Return' THEN Returns.MerchValue ELSE 0 END) AS TotalReturnPrice
FROM
(
    SELECT
        'Invoice' AS type,
        SalesTable.Year,
        SalesTable.Month,
        SalesTable.Customer,
        SUM(SalesTable.Invoice) AS MerchValue,
        MAX(SalesTable.Date) AS Date,
        CustomerTable.Salesperson
    FROM
        Database.dbo.SalesTable
    LEFT JOIN Database.dbo.CustomerTable ON CustomerTable.Customer = SalesTable.Customer
    WHERE
        SalesTable.DocumentType = 'I'
    GROUP BY
        SalesTable.Year,
        SalesTable.Month,
        SalesTable.Customer,
        CustomerTable.Salesperson
    UNION ALL
    SELECT
        'Return' AS type,
        YEAR(ReturnTable1.EntryDate) AS Year,
        MONTH(ReturnTable1.EntryDate) AS Month,
        ReturnTable1.Customer,
        SUM(ReturnTable2.Price * ReturnTable2.ReceivedQty) AS MerchValue,
        MAX(ReturnTable1.Date) AS Date,
        CustomerTable.Salesperson
    FROM
        Database.dbo.ReturnTable1
    LEFT JOIN Syspro1.dbo.ReturnTable2 ON ReturnTable2.RmaNumber = ReturnTable1.RmaNumber
    LEFT JOIN Syspro1.dbo.CustomerTable ON ArCustomer.Customer = ReturnTable1.Customer
    WHERE
        ReturnTable2.Price > 0
        AND ReturnTable2.ReceivedQty > 0
    GROUP BY
        YEAR(ReturnTable1.EntryDate),
        MONTH(ReturnTable1.EntryDate),
        ReturnTable1.Customer,
        CustomerTable.Salesperson
) AS Returns
GROUP BY
    Returns.Year,
    Returns.Month,
    Returns.Customer,
    Returns.Salesperson
```