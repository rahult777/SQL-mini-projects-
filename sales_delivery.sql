create database Sales_Delivery;
select * from cust_dimen;
select* from market_fact;

#Q1: Find the top 3 customers who have the maximum number of orders

SELECT m.cust_id,c.Customer_Name,count(m.Order_Quantity)max_number
from cust_dimen c
JOIN
market_fact m ON m.Cust_id = c.Cust_id
GROUP BY c.cust_id,Ord_id,c.Customer_Name
order by max_number desc
limit 3;

#Q2: Create a new column DaysTakenForDelivery that contains the date difference between Order_Date and Ship_Date.

ALTER TABLE Orders_Dimen
ADD DaysTakenForDelivery INT;

UPDATE orders_dimen od
JOIN shipping_dimen sd ON od.Order_ID = sd.Order_ID
SET od.DaysTakenForDelivery = DATEDIFF(STR_TO_DATE(sd.Ship_Date, '%d-%m-%Y'), STR_TO_DATE(od.Order_Date, '%d-%m-%Y'));
select * from orders_dimen;

#Question 3: Find the customer whose order took the maximum time to get delivered.

SELECT m.cust_id,c.Customer_Name,max(DaysTakenForDelivery) AS max_delivery_time 
FROM market_fact m
join 
orders_dimen o
on m.Ord_id=o.Ord_id
join
shipping_dimen s 
on s.Ship_id=m.Ship_id
join cust_dimen c
on c.cust_id=m.Cust_id
GROUP BY m.cust_id,c.Customer_Name
ORDER BY max_delivery_time DESC
LIMIT 1;


#Question 4: Retrieve total sales made by each product from the data (use Windows function)

SELECT p.Prod_id, SUM(Sales) OVER (PARTITION BY Prod_id ) AS TotalSales
FROM Market_Fact m
JOIN Prod_Dimen p ON M.Prod_id = P.Prod_id
order by totalsales desc; 

#Question 5: Retrieve the total profit made from each product from the data (use windows function)
  
SELECT p.Prod_id, Product_Category, SUM(Profit) OVER (PARTITION BY Prod_id)AS TotalProfit
FROM Market_Fact m
JOIN Prod_Dimen p ON M.Prod_id = P.Prod_id
order by totalprofit desc;

#Question 6: Count the total number of unique customers in January and how many of 
#them came back every month over the entire year in 2011

WITH JanuaryCustomers AS 
(SELECT DISTINCT c.Cust_id
  FROM market_fact m
  JOIN cust_dimen c ON c.Cust_id = m.Cust_id
  JOIN orders_dimen o ON o.Ord_id = m.Ord_id
  WHERE YEAR(STR_TO_DATE(o.Order_Date, '%d-%m-%Y')) = 2011
  AND MONTH(STR_TO_DATE(o.Order_Date, '%d-%m-%Y')) = 1
),

ReturningCustomers AS 
(SELECT m.Cust_id,o.Order_ID
FROM orders_dimen o
JOIN market_fact m ON m.Ord_id = o.Ord_id
WHERE YEAR(STR_TO_DATE(o.Order_Date, '%d-%m-%Y')) = 2011
GROUP BY m.Cust_id,o.Order_ID
HAVING COUNT(distinct MONTH(STR_TO_DATE(o.Order_Date, '%d-%m-%Y')))= 12
)

SELECT COUNT(*) AS UniqueCustomersInJanuary, COUNT(ReturningCustomers.Cust_id) AS ReturningCustomersIn2011
FROM JanuaryCustomers
left JOIN ReturningCustomers ON JanuaryCustomers.cust_id = ReturningCustomers.cust_id;



---------------------------------------------------------------------------------------------------------------------------
create database Restaurant;
# Part 2 – Restaurant:
select * from userprofile;
select * from chefmozaccepts;
select * from chefmozcuisine;
select * from  chefmozhours4;
select * from chefmozparking;
select * from  geoplaces2;
select * from usercuisine;
select * from rating_final;


#Q1: - We need to find out the total visits to all restaurants under all alcohol categories available.
select * from geoplaces2;
SELECT Alcohol, COUNT(*) AS TotalVisits
FROM geoplaces2
GROUP BY Alcohol;


#Q2: -Let's find out the average rating according to alcohol and
#price so that we can understand the rating in respective price categories as well.

SELECT Alcohol, Price, AVG(Rating) AS AvgRating
FROM geoplaces2 g join rating_final r 
on r.placeID=g.placeID
GROUP BY Alcohol, Price;

#Q3:  Let’s write a query to quantify that what are the parking availability as
#well in different alcohol categories along with the total number of restaurants.
select * from geoplaces2;
SELECT Alcohol, SUM(CASE WHEN Parking_lot IS NOT NULL THEN 1 ELSE 0 END) AS RestaurantsWithParking,
count(*) AS TotalRestaurants
FROM geoplaces2 g join 
chefmozparking c on c.placeID=g.placeID
GROUP BY Alcohol;

#Q4: Also take out the percentage of different cuisine in each alcohol type.
#Let us now look at a different prospect of the data to check state-wise rating.

SELECT Alcohol, Rcuisine, COUNT(*) AS CuisineCount,
(COUNT(*) * 100 / SUM(COUNT(*)) OVER(PARTITION BY Alcohol)) AS Percentage
FROM Chefmozcuisine c
JOIN geoplaces2 g ON c.PlaceID = g.PlaceID
GROUP BY Alcohol, Rcuisine;

#Q5: let’s take out the average rating of each state.


SELECT State, AVG(Rating) AS AvgRating
FROM geoplaces2 g
join rating_final r 
on r.placeID=g.placeID
GROUP BY State;

#Q6: -' Tamaulipas' Is the lowest average rated state. Quantify the reason why it is the lowest
#rated by providing the summary on the basis of State, alcohol, and Cuisine.

SELECT State, Alcohol, Rcuisine, AVG(Rating) AS AvgRating
FROM geoplaces2 g
join Chefmozcuisine c
ON c.PlaceID = g.PlaceID
join rating_final r 
on r.placeID=g.placeID
WHERE State = 'Tamaulipas'
GROUP BY State, Alcohol, Rcuisine;

#Q7:  - Find the average weight, food rating, and service rating of the customers
#who have visited KFC and tried Mexican or Italian types of cuisine, and also their budget level is low.
#We encourage you to give it a try by not using joins.

SELECT AVG(up.Weight) AS AvgWeight, AVG(rf.Food_Rating) AS AvgFoodRating, AVG(rf.Service_Rating) AS AvgServiceRating
FROM Userprofile up
INNER JOIN rating_final rf ON up.UserID = rf.UserID
INNER JOIN Usercuisine uc ON up.UserID = uc.UserID
WHERE uc.Rcuisine IN ('Mexican', 'Italian')
AND up.Budget = 'low' AND EXISTS 
(SELECT 1 FROM geoplaces2 gp WHERE gp.Name = 'KFC');

------------------------------------------------------------------------------------------------------------------------------
#Part3:  Triggers

#Q1:
#Create two called Student_details and Student_details_backup.
#Table 1: Attributes 		Table 2: Attributes
#Student id, Student name, mail id, mobile no.	Student id, student name, mail id, mobile no.
create database students;

CREATE TABLE Student_details (
    Student_id INT PRIMARY KEY,
    Student_name VARCHAR(255),
    mail_id VARCHAR(255),
    mobile_no VARCHAR(20));

-- Create the Student_details_backup table
CREATE TABLE Student_details_backup (
    Student_id INT PRIMARY KEY,
    Student_name VARCHAR(255),
    mail_id VARCHAR(255),
    mobile_no VARCHAR(20));



#You have the above two tables Students Details and Student Details Backup. Insert some records into Student details. 

#Problem:

#Let’s say you are studying SQL for two weeks. In your institute, 
#there is an employee who has been maintaining the student’s details and
#Student Details Backup tables. He / She is deleting the records from the Student details after 
#the students completed the course and keeping the backup in the student details
#backup table by inserting the records every time. You are noticing this daily 
#and now you want to help him/her by not inserting the records for backup purpose
#when he/she delete the records.write a trigger that should be capable enough to insert 
#the student details in the backup table whenever the employee deletes records from the student details table.

#Note: Your query should insert the rows in the backup table before deleting the records from student details.
DELIMITER //
CREATE TRIGGER BackupBeforeDelete
BEFORE DELETE ON Student_details
FOR EACH ROW
BEGIN
    INSERT INTO Student_details_backup (Student_id, Student_name, mail_id, mobile_no)
    VALUES (OLD.Student_id, OLD.Student_name, OLD.mail_id, OLD.mobile_no);
END;
//
DELIMITER ;

INSERT INTO Student_details (Student_id, Student_name, mail_id, mobile_no)
VALUES
    (1, 'John Doe', 'john@example.com', '123-456-7890'),
    (2, 'Jane Smith', 'jane@example.com', '987-654-3210');

-- Delete a record from the Student_details table (the trigger will insert it into the backup table)

DELETE FROM Student_details WHERE Student_id = 1;

-- Check the contents of both tables
SELECT * FROM Student_details;
SELECT * FROM Student_details_backup;