import xml.etree.ElementTree as ET
import pandas as pd
import numpy as np

def isLeap(year):
    if (year % 4) == 0:
        if (year % 100) == 0:
            if (year % 400) == 0:
                return True
            else:
                return False
        else:
             return True
    else:
        return False
    
    
def postsToDataframe(path):
    Id = []
    PostTypeId = []
    AcceptedAnswerId = [] 
    CreationDate = []
    Score = []
    ViewCount = []
    Body = [] 
    OwnerUserId = []
    OwnerDisplayName = []
    LastEditorUserId = []
    LastEditDate = []
    LastActivityDate = []
    Title = []
    Tags = []
    AnswerCount = []
    CommentCount = []
    ContentLicense = []

    tree = ET.parse(path)
    root = tree.getroot()

    for child in root:
        try:
            Id.append(child.attrib['Id'])
        except:
            Id.append(None)
        try: 
            PostTypeId.append(child.attrib['PostTypeId'])
        except:
            PostTypeId.append(None)
        try:
            CreationDate.append(child.attrib['CreationDate'])
        except:
            CreationDate.append(None)
        try:
            Score.append(child.attrib['Score'])
        except:
            Score.append(None)
        try:
            ViewCount.append(child.attrib['ViewCount'])
        except:
            ViewCount.append(None)
        try:
            CommentCount.append(child.attrib['CommentCount'])
        except:
            CommentCount.append(None)
        try:
            AnswerCount.append(child.attrib['AnswerCount'])
        except:
            AnswerCount.append(None)
        try:
            Title.append(child.attrib['Title'])
        except:
            Title.append(None)
        try:	
            OwnerUserId.append(child.attrib['OwnerUserId'])
        except:
            OwnerUserId.append(None)
            
    column_list = ['Id', 'PostTypeId', 'CreationDate', 'Score', 'ViewCount', 'CommentCount', 'AnswerCount', 'Title', 'OwnerUserId']
    posts = pd.DataFrame(list(zip(Id, PostTypeId, CreationDate, Score, ViewCount, CommentCount, AnswerCount, Title, OwnerUserId)),  columns= column_list)
    return posts

def commentsToDataframe(path):
    Id = []
    PostId = []
    CreationDate = []
    UserId = []
    
    tree = ET.parse(path)
    root = tree.getroot()

    for child in root:
        try:
            Id.append(child.attrib['Id'])
        except:
            Id.append(None)
        try: 
            PostId.append(child.attrib['PostId'])
        except:
            PostId.append(None)
        try:
            CreationDate.append(child.attrib['CreationDate'])
        except:
            CreationDate.append(None)
        try:
            UserId.append(child.attrib['UserId'])
        except:
            UserId.append(None)
            
    column_list = ['Id', 'PostId', 'CreationDate', 'UserId']
    comments = pd.DataFrame(list(zip(Id, PostId, CreationDate, UserId)),  columns= column_list)
    return comments
                                 
                                 
def usersToDataframe(path):
    Id = []
    Reputation = []
    CreationDate = []
    DisplayName = []
    UpVotes = []
    DownVotes = []
    Views = []
    Location = []
    
    tree = ET.parse(path)
    root = tree.getroot()

    for child in root:
        try:
            Id.append(child.attrib['Id'])
        except:
            Id.append(None)
        try: 
            Reputation.append(child.attrib['Reputation'])
        except:
            Reputation.append(None)
        try:
            CreationDate.append(child.attrib['CreationDate'])
        except:
            CreationDate.append(None)
        try:
            DisplayName.append(child.attrib['DisplayName'])
        except:
            DisplayName.append(None)
        try:
            UpVotes.append(child.attrib['UpVotes'])
        except:
            UpVotes.append(None)
        try:
            DownVotes.append(child.attrib['DownVotes'])
        except:
            DownVotes.append(None)
        try:
            Views.append(child.attrib['Views'])
        except:
            Views.append(None)
        try:
            Location.append(child.attrib['Location'])
        except:
            Location.append(None)
                                 
    column_list = ['Id', 'Reputation', 'CreationDate', 'DisplayName', 'UpVotes', 'DownVotes', 'Views', 'Location']
    print(Location[0])
    users = pd.DataFrame(list(zip(Id, Reputation, CreationDate, DisplayName, UpVotes, DownVotes, Views, Location)), columns= column_list)
    print(len(Location))
    return users
                              