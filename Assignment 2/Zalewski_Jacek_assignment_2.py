### Data Processing in R and Python 2022Z
### Homework Assignment no. 2
###
### IMPORTANT
### This file should contain only solutions to tasks in the form of a functions
### definitions and comments to the code.
###
def assign_period(VotesDates):
    if VotesDates['CreationDate'] < 2019: return 'before'
    elif VotesDates['CreationDate']<=2021 and VotesDates['CreationDate'] >= 2019: return 'during'
    else: return 'after'

# -----------------------------------------------------------------------------#
# Task 1
# -----------------------------------------------------------------------------#
import numpy as np
import pandas as pd

def solution_1(Posts):
    df = pd.DataFrame(pd.to_datetime(Posts['CreationDate']).dt.year)
    df = df.groupby(['CreationDate'], as_index=False).size()
    df.columns = ['Year', 'TotalNumber']
    return df
    
# -----------------------------------------------------------------------------#
# Task 2
# -----------------------------------------------------------------------------#
def solution_2(Posts, Users):
    users = Users[['Id', 'DisplayName']]
    questions = Posts.loc[Posts["PostTypeId"] == 1, ['OwnerUserId', 'ViewCount', 'PostTypeId']]
    df = users.merge(questions, left_on='Id', right_on='OwnerUserId')
    df = df.groupby(["Id", "DisplayName"], as_index=False)["ViewCount"].sum()
    df = df.sort_values(by=['ViewCount'], ascending = False)
    df.columns = ['Id', 'DisplayName', 'TotalViews']
    df = df.reset_index(drop=True) #start index from 0
    return df[:10]

# -----------------------------------------------------------------------------#
# Task 3
# -----------------------------------------------------------------------------#
def solution_3(Badges):
    BadgesTemp = Badges.loc[:,['Name', 'Date']]
    BadgesTemp['Date'] = pd.to_datetime(Badges['Date']).dt.year

    BadgesNames = BadgesTemp.groupby(["Date", "Name"], as_index=False).size()
    BadgesYearly = BadgesTemp.groupby(["Date"], as_index=False).size()
    result = BadgesNames.merge(BadgesYearly, left_on='Date', right_on='Date')
    result['MaxPercentage'] = result["size_x"] / result['size_y']

    result = result.loc[:, ['Date', 'Name', 'MaxPercentage']]
    result = result.sort_values(['Date','MaxPercentage'], ascending = False)
    result = result.drop_duplicates(subset=['Date']).sort_values(['Date'])
    result = result.reset_index(drop=True)
    result.columns = ['Year', 'Name', 'MaxPercentage']
    return result
    
# -----------------------------------------------------------------------------#
# Task 4
# -----------------------------------------------------------------------------#
def solution_4(Comments, Posts, Users):
    CmtToScr = Comments.groupby(["PostId"], as_index=False)["Score"].sum()
    CmtToScr.columns = ['PostId', 'CommentsTotalScore']
    PostType1 = Posts[Posts["PostTypeId"] == 1]
    PostsBestComments = CmtToScr.merge(PostType1, left_on='PostId', right_on='Id')
    result = PostsBestComments.merge(Users, left_on ='OwnerUserId', right_on = 'Id')
    result= result.loc[:,['Title', 'CommentCount', 'ViewCount', 'CommentsTotalScore', 'DisplayName', 'Reputation', 'Location']]
    result = result.sort_values(['CommentsTotalScore'], ascending = False)[:10]
    return result.reset_index(drop = True)
    

# -----------------------------------------------------------------------------#
# Task 5
# -----------------------------------------------------------------------------#
def solution_5(Votes, Posts):
    VotesDates = Votes.loc[:,['CreationDate', 'VoteTypeId', 'PostId']]
    VotesDates = VotesDates.loc[VotesDates['VoteTypeId'].isin([3,4,12])]
    VotesDates['CreationDate'] = pd.to_datetime(VotesDates['CreationDate']).dt.year
    VotesDates['VoteDate'] = VotesDates.apply(assign_period, axis=1)
    VotesDates = VotesDates.groupby(["PostId", "VoteDate"], as_index=False).size()
    VotesDates.columns = ['PostId', 'VoteDate', 'Total']

    VotesDates['BeforeCOVIDVotes'] = np.where(VotesDates['VoteDate'] == 'before', VotesDates['Total'], 0)
    VotesDates['DuringCOVIDVotes'] = np.where(VotesDates['VoteDate'] == 'during', VotesDates['Total'], 0)
    VotesDates['AfterCOVIDVotes'] = np.where(VotesDates['VoteDate'] == 'after', VotesDates['Total'], 0)

    totalSumByPostId = VotesDates.groupby(["PostId"], as_index=False)["Total"].sum()
    maxBeforeCovidByPostId = VotesDates.groupby(["PostId"], as_index=False)["BeforeCOVIDVotes"].max()
    maxDuringCovidByPostId = VotesDates.groupby(["PostId"], as_index=False)["DuringCOVIDVotes"].max()
    maxAfterCovidByPostId = VotesDates.groupby(["PostId"], as_index=False)["AfterCOVIDVotes"].max()

    VotesByAge = totalSumByPostId.merge(maxBeforeCovidByPostId, on = 'PostId')
    VotesByAge = VotesByAge.merge(maxDuringCovidByPostId, on = 'PostId')
    VotesByAge = VotesByAge.merge(maxAfterCovidByPostId, on = 'PostId')

    PostsInfo = Posts.loc[:,['Title', 'Id', 'CreationDate']]
    PostsInfo['Date'] = pd.to_datetime(PostsInfo['CreationDate']).dt.date
    result = VotesByAge.merge(PostsInfo, left_on = 'PostId', right_on = 'Id')

    result = result[result["Title"].isnull() == False]
    result = result[result["DuringCOVIDVotes"] >0]
    result = result.sort_values(['DuringCOVIDVotes', 'Total'], ascending = [False, False])
    result = result.head(20)
    result.columns = result.columns.str.replace('Total', 'Votes')
    result = result.reset_index(drop=True)
    return result[['Title', 'Date', 'PostId', 'BeforeCOVIDVotes', 'DuringCOVIDVotes', 'AfterCOVIDVotes', 'Votes']]
