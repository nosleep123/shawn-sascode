import requests
from bs4 import BeautifulSoup
from csv import writer
import pandas as pd
import numpy as np

search_city =  ['Alexandria', 'Arlington', 'Annapolis', 'Adelphi', 'Annandale',
                'Beltsville', 'Baltimore',
                'Columbia', 'College+Park', 'Clarksburg', 'Chevy+Chase', 'Calverton', 'Colesville', 'Clarksville',
                'Ellicot+City',
                'Farifax', 'Falls+Church', 'Frederick', 'Fulton', 'Fort+Meade', 'Fairland',
                'Gaithersberg', 'Greenbelt', 'Germantown',
                'Hyattsville', 'Hanover',
                'Laurel',
                'Mclean',
                'New+Carrollton',
                'Olney',
                'Potomac',
                'Rockville', 'Reston',
                'Silver+Spring', 'Springfield',
                'Tysons+Corner', 'Tysons', 'Towson',
                'Vienna',
                'Washington+DC', 'WASHINGTON%2C+D.C.', 'Wheaton', 'White+Oak']

# print(soup.prettify())

# for link in soup.find_all("a"):
#     print(link.text, link.get('href'))



with open('/Users/shuhao/PycharmProjects/Learning/H1B.csv', 'w') as csv_file:
    csv_writer = writer(csv_file)
    headers = ['Company', 'Job_Title', 'Base_Salary', 'Location', 'Start_Date', 'End_Date', 'Cas_Status']
    csv_writer.writerow(headers)

    # for city in search_city:
    for city in search_city:
        url = 'https://h1bdata.info/index.php?em=&job=&city=' + city + '&year=All+Years'
        print('Get link for ' + city + '!!')

        r = requests.get(url)
        content = r.content
        soup = BeautifulSoup(content, 'html.parser')
        posts = soup.find(id='myTable')
        for tr in posts.find_all('tr'):
            data = []
            for td in tr.find_all('td'):

                data.append(td.get_text())
            row = np.array(data)
            csv_writer.writerow([row[0:1], row[1:2], row[2:3], row[3:4], row[4:5], row[5:6], row[6:7]])


