# Data Processing in R and Python

## Description 
The repository contains a solution from a Data processing in R and Python course.  

## Assignment 1
We are working on a simplified dump of anonymised data from the website https://travel.stackexchange.com/
(by the way: full data set is available at https://archive.org/details/stackexchange).

In the task we have to rewrite sql queries using base functions calls and those provided by the dplyr andd ata.table package.
Furthermore efficiency of all packages is compared. Results of comparision are presented in `Zalewski_Jacek_assignment_1.html` and `Zalewski_Jacek_assignment_1.rmd`

Queries
```
--- 1)
SELECT STRFTIME('%Y', CreationDate) AS Year, COUNT(*) AS TotalNumber
FROM Posts
GROUP BY Year
```


```
--- 2)
SELECT Id, DisplayName, SUM(ViewCount) AS TotalViews
FROM Users
JOIN (
SELECT OwnerUserId, ViewCount FROM Posts WHERE PostTypeId = 1
) AS Questions
ON Users.Id = Questions.OwnerUserId
GROUP BY Id
ORDER BY TotalViews DESC
LIMIT 10
```


```
--- 3)
ELECT Year, Name, MAX((Count * 1.0) / CountTotal) AS MaxPercentage
FROM (
SELECT BadgesNames.Year, BadgesNames.Name, BadgesNames.Count, BadgesYearly.CountTotal
FROM (
SELECT Name, COUNT(*) AS Count, STRFTIME('%Y', Badges.Date) AS Year
FROM Badges
GROUP BY Name, Year
) AS BadgesNames
JOIN (
SELECT COUNT(*) AS CountTotal, STRFTIME('%Y', Badges.Date) AS Year
FROM Badges
GROUP BY YEAR
) AS BadgesYearly
ON BadgesNames.Year = BadgesYearly.Year
)
GROUP BY Year
```

```
--- 4)
SELECT Title, CommentCount, ViewCount, CommentsTotalScore, DisplayName, Reputation, Location
FROM (
SELECT Posts.OwnerUserId, Posts.Title, Posts.CommentCount, Posts.ViewCount,
CmtTotScr.CommentsTotalScore
FROM (
SELECT PostId, SUM(Score) AS CommentsTotalScore
FROM Comments
GROUP BY PostId
) AS CmtTotScr
JOIN Posts ON Posts.Id = CmtTotScr.PostId
WHERE Posts.PostTypeId=1
) AS PostsBestComments
JOIN Users ON PostsBestComments.OwnerUserId = Users.Id
ORDER BY CommentsTotalScore DESC
LIMIT 10
```

```
--- 5)
SELECT Posts.Title, STRFTIME('%Y-%m-%d', Posts.CreationDate) AS Date, VotesByAge.*
FROM Posts
JOIN (
SELECT PostId,
MAX(CASE WHEN VoteDate = 'before' THEN Total ELSE 0 END) BeforeCOVIDVotes,
MAX(CASE WHEN VoteDate = 'during' THEN Total ELSE 0 END) DuringCOVIDVotes,
MAX(CASE WHEN VoteDate = 'after' THEN Total ELSE 0 END) AfterCOVIDVotes,
SUM(Total) AS Votes
FROM (
SELECT PostId,
CASE STRFTIME('%Y', CreationDate)
WHEN '2022' THEN 'after'
WHEN '2021' THEN 'during'
WHEN '2020' THEN 'during'
WHEN '2019' THEN 'during'
ELSE 'before'
END VoteDate, COUNT(*) AS Total
FROM Votes
WHERE VoteTypeId IN (3, 4, 12)
GROUP BY PostId, VoteDate
) AS VotesDates
GROUP BY VotesDates.PostId
) AS VotesByAge ON Posts.Id = VotesByAge.PostId
WHERE Title NOT IN ('') AND DuringCOVIDVotes > 0
ORDER BY DuringCOVIDVotes DESC, Votes DESC
LIMIT 20
```
## Assignment 2
Implementation of the same queries with use of python pandas module. Results in `Zalewski_Jacek_assignment_2.ipynb`


## Assignment 3
This homework is a data science challenge - find interesting questions and generates answers to them.
Datasets: https://archive.org/details/stackexchange
1. health
2. raspberrypi
3. aviation
4. gardening
5. magento

Questions: 
1. Seasonalities in the datasets
2. Does activity of a raspberrypi stack exchange depends on release dates of new products?
3. Where are users coming from?








