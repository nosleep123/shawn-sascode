
import logging
import os

DEFAULT_DATA_PATH = os.path.abspath(os.path.join(
    os.path.dirname('/Users/shuhao/PycharmProjects/Learning/data/SEC'), '..', 'SEC-Edgar-Data'))

# -*- coding:utf-8 -*-
# This script will download all the 10-K, 10-Q and 8-K
# provided that of company symbol and its cik code.
class HoldingInfoNotFoundException(Exception):
    pass

import requests
import os
import errno
from bs4 import BeautifulSoup
import pandas as pd
import numpy as np

cik_list = pd.read_csv('/Users/shuhao/Dropbox/Python Project/CIK-2010.csv')

class SecCrawler():

    def __init__(self):
        self.hello = "Welcome to Sec Cralwer!"
        print("Path of the directory where data will be saved: " + DEFAULT_DATA_PATH)

    def make_directory(self, cik, filing_type):
        # Making the directory to save comapny filings
        path = os.path.join(DEFAULT_DATA_PATH, cik, filing_type)

        if not os.path.exists(path):
            try:
                os.makedirs(path)
            except OSError as exception:
                if exception.errno != errno.EEXIST:
                    raise

    def save_in_directory(self, cik=None, doc_list=None,
        doc_name_list=None, filing_type=None):
        # Save every text document into its respective folder
        for j in range(len(doc_list)):
            base_url = doc_list[j]
            r = requests.get(base_url)
            data = r.text
            path = os.path.join(DEFAULT_DATA_PATH, cik,
                filing_type, doc_name_list[j])

            with open(path, "ab") as f:
                f.write(data.encode('ascii', 'ignore'))



    def filing_NQ(self,cik, count):

        self.make_directory(cik=cik, filing_type='NQ')

        # generate the url to crawl
        base_url = "https://www.sec.gov/cgi-bin/browse-edgar?action=getcompany&CIK="+str(cik)+"&type=N-Q&owner=exclude&output=xml&count=" +str(count)
        print("started N-Q " + str(cik))
        r = requests.get(base_url)
        data = r.text

        print(data)

        # get doc list data

        doc_list, doc_name = self.create_document_list(data)
        # try:
        #     doc_list, doc_name_list = self.create_document_list(data)
        # except:
        #     erro_cik = erro_cik.append(cik)
        #     pass

        try:
            self.save_in_directory(cik=cik, filing_type='NQ', doc_list=doc_list, doc_name_list=doc_name_list)
        except Exception as e:
            print(str(e))

        print("Successfully downloaded all the files")

    def create_document_list(self, data):

        # parse fetched data using beatifulsoup
        soup = BeautifulSoup(data)
        # store the link in the list
        link_list = list()

        # If the link is .htm convert it to .html
        for link in soup.find_all('filinghref'):
            url = link.string
            if link.string.split(".")[len(link.string.split("."))-1] == "htm":
                url += "l"
            link_list.append(url)
        link_list_final = link_list

        print ("Number of files to download {0}".format(len(link_list_final)))
        print ("Starting download....")

        # List of url to the text documents
        doc_list = list()
        # List of document names
        doc_name_list = list()
        if len(link_list_final) == 0:
            pass
        else:

            # Get all the doc
            # for k in range(len(link_list_final)):
            for k in range(1):
                required_url = link_list_final[k].replace('-index.html', '')
                txtdoc = required_url + ".txt"
                docname = txtdoc.split("/")[-1]
                doc_list.append(txtdoc)
                doc_name_list.append(docname)
        return doc_list, doc_name_list


for cik in cik_list['CIK Number']:

    data = SecCrawler()
    get_report = data.filing_NQ('000'+ str(cik), '1')
