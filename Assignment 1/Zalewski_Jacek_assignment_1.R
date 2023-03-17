#NOTE: Comments only for base function as for dplyr and data.table the task is done in a similar way
# -----------------------------------------------------------------------------#
# Task 1
# -----------------------------------------------------------------------------#
sqldf_1 <- function(Posts){
  result <- sqldf("SELECT STRFTIME('%Y', CreationDate) AS Year,
                   COUNT(*) AS TotalNumber FROM Posts
                   GROUP BY Year")
  
  #conversion needed for comparing equivalence of solutions
  result[,1] <- as.numeric(result[,1])
  return (result)
}

base_1 <- function(Posts){
  #rle - compute the lengths and values of runs of equal values in a vector
  result <- as.data.frame(do.call(cbind, rle(sort(as.numeric(format(as.Date(Posts$CreationDate), format = "%Y"))))))
  colnames(result) <- c('TotalNumber', 'Year')
  return(result)
}

dplyr_1 <- function(Posts){
  df <- Posts %>%
        transmute(Year = as.numeric(format(as.Date(Posts$CreationDate),"%Y"))) %>%         
        group_by(Year) %>% count(name = 'TotalNumber')                                      
  return (as.data.frame(df))
}

data.table_1 <- function(Posts){                                                
  dt = as.data.table(Posts)[, "CreationDate"]                                  
  dt <- dt[,CreationDate:=as.numeric(format(as.Date(CreationDate),"%Y"))]       
  colnames(dt) = "Year"
  #.N - counting grouped elements
  return (dt[, .(TotalNumber = .N), by = Year])                                 
}

# -----------------------------------------------------------------------------#
# Task 2
# -----------------------------------------------------------------------------#
sqldf_2 <- function(Users, Posts){
  sqldf('SELECT Id, DisplayName, SUM(ViewCount) AS TotalViews FROM Users
  JOIN (
    SELECT OwnerUserId, ViewCount FROM Posts WHERE PostTypeId = 1
  ) AS Questions
  ON Users.Id = Questions.OwnerUserId
  GROUP BY Id
  ORDER BY TotalViews DESC
  LIMIT 10')
}

base_2 <- function(Users, Posts){
  #subset only needed columns, only posts of type 1
  users <- Users[,c('Id', 'DisplayName')]
  questions <- Posts[Posts$PostTypeId==1, c('OwnerUserId', 'ViewCount', 'PostTypeId')]
  
  #merge users with the posts they own
  df <- merge(users, questions, by.x ='Id' , by.y = 'OwnerUserId')
  
  #find top 10 users that owns posts with highest view count
  agg_df <- aggregate(df$ViewCount, list(df$Id, df$DisplayName), FUN=sum)
  colnames(agg_df) <- c('Id','DisplayName', 'TotalViews')
  head(agg_df[order(-agg_df$TotalViews),], 10)
}

dplyr_2 <- function(Users, Posts){
  users <- Users %>% select(Id, DisplayName)
  posts <- Posts %>% select(OwnerUserId, ViewCount, PostTypeId)%>%
                     filter(is.na(PostTypeId) == FALSE, PostTypeId == 1)
  result <- inner_join(users, posts , by = c("Id" = "OwnerUserId"))%>%
          group_by(Id, DisplayName)%>% 
          summarise(TotalViews = sum(ViewCount), .groups = 'drop')%>%
          arrange(-TotalViews) %>%
          top_n(10, TotalViews)
  return (as.data.frame(result))
}

data.table_2 <- function(Users, Posts){
  users = as.data.table(Users)
  users <- users[, .(Id, DisplayName)]
  posts = as.data.table(Posts)
  posts <- posts[, .(OwnerUserId, ViewCount, PostTypeId)]
  dt <- merge(users, posts, by.x ='Id' , by.y = 'OwnerUserId')
  dt <- dt[PostTypeId ==1]
  dt <- dt[, .(TotalViews = sum(ViewCount)),by=.(Id, DisplayName)]
  dt <- dt[order(-TotalViews)] 
  return(dt[1:10,])
}

# -----------------------------------------------------------------------------#
# Task 3
# -----------------------------------------------------------------------------#
sqldf_3 <- function(Badges){
  result <- sqldf("SELECT Year, Name, MAX((Count * 1.0) / CountTotal) AS MaxPercentage
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
        GROUP BY Year")
  result[,1] <- as.numeric(result[,1])
  return (result)
        
}

base_3 <- function(Badges){
  #counting number of badges by type in each year
  BadgesNames <- aggregate(Id ~ Name + as.numeric(format(as.Date(Badges$Date), format = "%Y")),
                           data = Badges,
                           length)
  colnames(BadgesNames) <- c('Name', 'Year', 'Count')
  
  #counting number of all badges in each year
  BadgesYearly = aggregate(Id ~ as.numeric(format(as.Date(Badges$Date), format = "%Y")),
                           data = Badges,
                           length)
  colnames(BadgesYearly) <- c('Year', 'CountTotal')
  
  #calculating "popularity" of badge each year and selecting the most popular badge of the year
  df <- merge(BadgesNames, BadgesYearly, by = "Year")
  df$MaxPercentage <- df$Count/df$CountTotal
  bb <- by(data = df, INDICES = list(df$Year), function(x) x[which.max(x$MaxPercentage), ])
  df2 <- do.call(rbind, bb)
  result <- df2[,c('Year', 'Name', 'MaxPercentage')]
  row.names(result) <- NULL
  return (result)
}

dplyr_3 <- function(Badges){
  BadgesNames <- Badges %>%
                 mutate(Year = as.numeric(format(as.Date(Badges$Date),"%Y"))) %>%
                 select(Name, Year) %>%
                 group_by(Name, Year) %>%
                 summarise(Count = n(), .groups = 'drop')
  BadgesYearly <- Badges %>%
                 mutate(Year = as.numeric(format(as.Date(Badges$Date),"%Y"))) %>%
                 select(Id, Name, Year) %>%
                 group_by(Year) %>%
                 summarise(CountTotal = n(), .groups = 'drop')
  
  result <- left_join(BadgesNames, BadgesYearly, by = "Year") %>%
            mutate(MaxPercentage = Count / CountTotal) %>%
            group_by(Year) %>%
            filter(MaxPercentage == max(MaxPercentage)) %>%
            select(Year, Name, MaxPercentage) %>%
            arrange(Year)
  return (as.data.frame(result))
}

data.table_3 <- function(Badges){
  BadgesNames <- as.data.table(Badges)[, .(Name, Date)]
  BadgesNames[, Year:= as.numeric(format(as.Date(Badges$Date),"%Y"))]
  BadgesNames <- BadgesNames[, .(Count = .N), by=.(Year, Name) ]
  
  BadgesYearly <- as.data.table(Badges)[, .(Name, Date)]
  BadgesYearly[, Year:= as.numeric(format(as.Date(Badges$Date),"%Y"))]
  BadgesYearly <-  BadgesYearly[, .(TotalCount = .N), by=.(Year)]
  
  result <- merge(BadgesNames, BadgesYearly, by = "Year")
  result[, MaxPercentage:= Count /TotalCount]
  result <- result[, .SD[which.max(MaxPercentage)], by = Year]
  result <-  result[, .(Year, Name, MaxPercentage)]
  return(result)
}

# -----------------------------------------------------------------------------#
# Task 4
# -----------------------------------------------------------------------------#
sqldf_4 <- function(Comments, Posts, Users){
  sqldf('SELECT Title, CommentCount, ViewCount, CommentsTotalScore, DisplayName, Reputation, Location
         FROM (
            SELECT Posts.OwnerUserId, Posts.Title, Posts.CommentCount, Posts.ViewCount, CmtTotScr.CommentsTotalScore
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
        LIMIT 10')
}

base_4 <- function(Comments, Posts, Users){
  
 #selecting posts with highest score of comments
 CmtToScr <- aggregate(Score ~ PostId,
                          data = Comments,
                          sum)
 colnames(CmtToScr)[2]<- c("CommentsTotalScore")
 
 #subseting to post of type 1
 PostsType1 <- Posts[Posts$PostTypeId==1,]
 PostsBestComments <- merge(CmtToScr,PostsType1, by.x ='PostId' , by.y = 'Id')
 PostsBestComments <- PostsBestComments[, c('OwnerUserId','Title', 'CommentCount', 'ViewCount', 'CommentsTotalScore')]
 
 #merging best posts with owners and order by score and select 10 highest
 result <-  merge(PostsBestComments, Users, by.x = 'OwnerUserId', by.y = 'Id')
 result <- result[,c('Title', 'CommentCount', 'ViewCount', 'CommentsTotalScore', 'DisplayName', 'Reputation', 'Location')]
 result <- result[order(-result$CommentsTotalScore),]
 return(head(result, n=10))
}

dplyr_4 <- function(Comments, Posts, Users){
  CmtToScr <-  Comments %>%
               group_by(PostId) %>%
               summarise(CommentsTotalScore = sum(Score))
  PostsType1 <- Posts %>% filter(PostTypeId==1)
  PostsBestComments <- inner_join(CmtToScr, PostsType1, by = c("PostId"="Id")) %>%
                       select(OwnerUserId, Title, CommentCount, ViewCount, CommentsTotalScore)
  
  result <- inner_join(PostsBestComments, Users, by = c("OwnerUserId" = "Id"))%>%
            select(Title, CommentCount, ViewCount, CommentsTotalScore, DisplayName, Reputation, Location) %>%
            arrange(-CommentsTotalScore) %>%
            slice(1:10)
  return(as.data.frame(result))
}

data.table_4 <- function(Comments, Posts, Users){
  CmtToScr <- as.data.table(Comments)[, .(CommentsTotalScore = sum(Score)), by=.(PostId)]
  PostType1 <- as.data.table(Posts)[PostTypeId == 1]
  PostsBestComments <- merge(CmtToScr, PostType1, by.x = 'PostId', by.y = 'Id') 
  results <- merge(PostsBestComments, as.data.table(Users), by.x = 'OwnerUserId', by.y = 'Id')
  results <- results[, .(Title, CommentCount, ViewCount, CommentsTotalScore, DisplayName, Reputation, Location)]
  results <- results[order(-CommentsTotalScore)]
  return (results[1:10,])
}

# -----------------------------------------------------------------------------#
# Task 5
# -----------------------------------------------------------------------------#
sqldf_5 <- function(Posts, Votes){
  result <- sqldf("SELECT Posts.Title, STRFTIME('%Y-%m-%d', Posts.CreationDate) AS Date, VotesByAge.* FROM Posts
         JOIN (
            SELECT PostId,
              MAX(CASE WHEN VoteDate = 'before' THEN Total ELSE 0 END) BeforeCOVIDVotes,
              MAX(CASE WHEN VoteDate = 'during' THEN Total ELSE 0 END) DuringCOVIDVotes,
              MAX(CASE WHEN VoteDate = 'after' THEN Total ELSE 0 END) AfterCOVIDVotes, SUM(Total) AS Votes FROM (
                SELECT PostId,
                  CASE STRFTIME('%Y', CreationDate)
                    WHEN '2022' THEN 'after'
                    WHEN '2021' THEN 'during'
                    WHEN '2020' THEN 'during'
                    WHEN '2019' THEN 'during'
                  ELSE 'before'
                END 
                VoteDate, COUNT(*) AS Total
                FROM Votes
                WHERE VoteTypeId IN (3, 4, 12)
                GROUP BY PostId, VoteDate
                ) AS VotesDates
              GROUP BY VotesDates.PostId
              ) AS VotesByAge ON Posts.Id = VotesByAge.PostId
              WHERE Title NOT IN ('') AND DuringCOVIDVotes > 0
              ORDER BY DuringCOVIDVotes DESC, Votes DESC LIMIT 20
          ")
  result[,2] <- as.Date(result[,2])
  return(result)
}

base_5 <- function(Posts, Votes){
   #select votes of type 3,4,12 and assign label depending on year
   VotesOfSelectedType <- Votes[Votes$VoteTypeId %in% c(3,4,12), c('CreationDate', 'VoteTypeId', 'PostId')]
   VotesOfSelectedType$CreationDate <- as.numeric(format(as.Date(VotesOfSelectedType $CreationDate), format = "%Y"))
   VotesOfSelectedType$CreationDate[VotesOfSelectedType$CreationDate == 2022] <- 'after'
   VotesOfSelectedType$CreationDate[VotesOfSelectedType$CreationDate <= 2021 & VotesOfSelectedType$CreationDate >=2019] <- 'during'
   VotesOfSelectedType$CreationDate[VotesOfSelectedType$CreationDate < 2019] <- 'before'
   colnames(VotesOfSelectedType)[1] <- 'VoteDate'
   VotesOfSelectedType$Total <- 0
   
   #get number of votes received grouped by Post and the year
   VotesDates <- aggregate(Total ~ PostId + VoteDate,
                            data = VotesOfSelectedType,
                            length)
   
   #adding new columns representing votes received in 3 different time periods
   VotesDates$BeforeCOVIDVotes <- ifelse(VotesDates$VoteDate=='before', VotesDates$Total,0)
   VotesDates$DuringCOVIDVotes <- ifelse(VotesDates$VoteDate=='during', VotesDates$Total,0)
   VotesDates$AfterCOVIDVotes <- ifelse(VotesDates$VoteDate=='after', VotesDates$Total,0)
   
   #total votes in all time periods
   totalSumByPostId <- aggregate(Total ~ PostId,
                            data = VotesDates,
                            sum)
   
   colnames(totalSumByPostId)[2] = 'Votes'
   
   #find maximal number
   maxBeforeCovidByPostId <- aggregate(BeforeCOVIDVotes ~ PostId,
                            data = VotesDates,
                            max)
   maxDuringCovidByPostId <- aggregate(DuringCOVIDVotes ~ PostId,
                            data = VotesDates,
                            max)
   maxAfterCovidByPostId <- aggregate(AfterCOVIDVotes ~ PostId,
                            data = VotesDates,
                            max)
   
   #create information from aggregated data about the post
   temp <- merge(totalSumByPostId, maxBeforeCovidByPostId, by ='PostId')
   temp <- merge(temp, maxDuringCovidByPostId, by ='PostId')
   VotesByAge <- merge(temp, maxAfterCovidByPostId, by ='PostId')
   colnames(VotesByAge)[2] = 'Votes'
   
   #obtain information about post
   posts_df <- Posts[, c('Id','Title','CreationDate')]
   posts_df$CreationDate = as.Date(posts_df$CreationDate)
   
   #merge post information with aggregated data
   result <- merge(VotesByAge, posts_df, by.x='PostId', by.y = 'Id')
   result <- result[result$Title !='' & result$DuringCOVIDVotes > 0, ]
   result <- result[order(-result$DuringCOVIDVotes, -(result$Votes)),]
   colnames(result)[7] = 'Date'
   head(result, 20)
}

dplyr_5 <- function(Posts, Votes){ 
   VotesDates <- Votes %>% select(CreationDate, VoteTypeId, PostId)%>%
                           filter(VoteTypeId == 3 | VoteTypeId == 4 | VoteTypeId == 12) %>%
                           mutate(CreationDate = as.numeric(format(as.Date(CreationDate),"%Y"))) %>%
                           mutate(VoteDate = case_when(CreationDate  < 2019 ~'before',
                                                       CreationDate >= 2019 & CreationDate <=2021 ~ 'during',
                                                       CreationDate == 2022 ~ 'after')) %>%
                           group_by(PostId, VoteDate) %>%
                           summarise(Total = n()) %>%
                           mutate(BeforeCOVIDVotes = ifelse(VoteDate == 'before', Total, 0)) %>%
                           mutate(DuringCOVIDVotes = ifelse(VoteDate == 'during', Total, 0)) %>%
                           mutate(AfterCOVIDVotes = ifelse(VoteDate == 'after' , Total ,0))
   VotesByAge <- VotesDates %>% 
                 group_by(PostId) %>%
                 summarise(BeforeCOVIDVotes = max(ifelse(VoteDate == 'before', Total, 0)),
                           DuringCOVIDVotes = max(ifelse(VoteDate == 'during', Total, 0)),
                           AfterCOVIDVotes = max(ifelse(VoteDate == 'after', Total, 0)),
                           Votes = sum(Total))
             
             
   result <- Posts %>% select(Id, Title, CreationDate) %>%
     mutate(CreationDate = as.Date(CreationDate)) %>%
     inner_join(VotesByAge, by = c("Id" = "PostId")) %>%
     filter(Title != '', DuringCOVIDVotes > 0) %>%
     arrange(-DuringCOVIDVotes, -Votes)%>%
     slice(1:20) %>%
     rename(PostId = Id) %>%
     rename(Date = CreationDate)
  return(result)
}

data.table_5 <- function(Posts, Votes){
  VotesDates <-  as.data.table(Votes)[VoteTypeId == 3 | VoteTypeId == 4 | VoteTypeId == 12, .(CreationDate, VoteTypeId, PostId)]
  VotesDates[, CreationDate:= as.numeric(format(as.Date(CreationDate),"%Y"))]
  VotesDates[CreationDate  < 2019, VoteDate:= 'before']
  VotesDates[CreationDate >= 2019 & CreationDate <=2021, VoteDate:= 'during']
  VotesDates[CreationDate == 2022, VoteDate:= 'after']
  VotesDates <-  VotesDates[, .(Total = .N), by=.(PostId, VoteDate)]
  VotesDates[, BeforeCOVIDVotes := ifelse(VoteDate == 'before', Total, 0)]
  VotesDates[, DuringCOVIDVotes := ifelse(VoteDate == 'during', Total, 0)]
  VotesDates[, AfterCOVIDVotes := ifelse(VoteDate == 'after', Total, 0)]
  
  totalSumByPostId <- VotesDates[, .(Total = sum(Total)), by=.(PostId)]
  maxBeforeCovidByPostId <- VotesDates[, .(BeforeCOVIDVotes = max(BeforeCOVIDVotes)), by=.(PostId)]
  maxDuringCovidByPostId <- VotesDates[, .(DuringCOVIDVotes = max(DuringCOVIDVotes)), by=.(PostId)]
  maxAfterCovidByPostId <- VotesDates[, .(AfterCOVIDVotes = max(AfterCOVIDVotes)), by=.(PostId)]
  
  VotesByAge <- merge(totalSumByPostId, maxBeforeCovidByPostId, by = 'PostId')
  VotesByAge <- merge(VotesByAge, maxDuringCovidByPostId, by = 'PostId')
  VotesByAge <- merge(VotesByAge, maxAfterCovidByPostId, by = 'PostId')
  colnames(VotesByAge)[2] = 'Votes'
  
  posts_table <-  as.data.table(Posts)[ , .(Id, Title, CreationDate)]
  posts_table[, CreationDate:= as.Date(CreationDate)]
  
  result <- merge(VotesByAge,posts_table, by.x='PostId', by.y = 'Id')
  result <- result[Title != '' & DuringCOVIDVotes > 0]
  result <- result[order(-DuringCOVIDVotes, -Votes)]
  colnames(result)[7] <- c("Date")
  return (result[1:20, ])
}