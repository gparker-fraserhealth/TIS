-- usage: mysql -u FHA_ReadOnly -p -h your_host_name frb-live < export_was_sessions.sql
--

-- Connect to the database
USE frb-live;

-- Execute the query and export the results to a CSV file
SELECT servers.ServerIP, 
       COUNT(session.SessionID) AS "Num Sessions",
       NOW() AS "Current DateTime"
INTO OUTFILE CONCAT('C:/Monitoring/WAS_Sessions_', DATE_FORMAT(NOW(), '%Y%m%d_%H%i%s'), '.csv')
FIELDS TERMINATED BY ',' 
ENCLOSED BY '"'
LINES TERMINATED BY '\n'
FROM session
JOIN servers ON session.Servers_ServerId = servers.ServerId
GROUP BY servers.ServerIP;