/* Tam, Vincent -- CS5200, Fall 2022 */
/* Q1 */
SELECT DISTINCT COUNT(*) FROM Worker WHERE salary >= 250000;
/* Q2 */
SELECT Worker.last_name,Title.WORKER_TITLE, Worker.department FROM Worker INNER JOIN Title ON Worker.WORKER_ID = Title.WORKER_REF_ID Where Worker.salary < (SELECT AVG(salary) FROM Worker);
/* Q3 */
SELECT DISTINCT department, AVG(salary) OVER(partition by department) AvgSal, COUNT(*) OVER(partition By department) Num FROM Worker;
/* Q4 */
SELECT Worker.FIRST_NAME, Worker.LAST_NAME, Title.worker_title, ROUND((IFNULL(Bonus.BONUS_AMOUNT,0) + Worker.salary)/12, 0) AS MonthlyComp from Worker inner join Title on Worker.worker_id = Title.WORKER_REF_ID full join Bonus on Worker.WORKER_ID = Bonus.WORKER_REF_ID;
/* Q5 */
SELECT UPPER(Worker.first_name) As FirstName, UPPER(Worker.last_name) AS LastName FROM Worker full join Bonus On Worker.WORKER_ID = Bonus.WORKER_REF_ID WHERE Bonus.bonus_amount ISNULL;
/* Q6 */
SELECT * FROM Worker INNER JOIN Title ON Worker.WORKER_ID = Title.worker_ref_id WHERE Title.worker_title LIKE "%Manager%";

