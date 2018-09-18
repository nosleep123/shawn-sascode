
# -*- coding:utf-8 -*-

"""
This script will download all the historical mutual fund holdings from SEC EDGAR,
using the master file of SEC with the fund's names, CIK, submitted dates, and the text file addresses
provided that cik, form type, and submitted datetime code.

"""


import requests
import os
import pandas as pd


cik_list = pd.read_csv('/Users/shuhao/PycharmProjects/Learning/SEC-Edgar-Data/MF_filings.csv')

base_path = '/Users/shuhao/Dropbox/SEC_MF_Holdings/filings/'


file_list = []
for root, dirs, files in os.walk('/Users/shuhao/Dropbox/SEC_MF_Holdings/filings/'):# 注意：这里请填写数据文件在您电脑中的路径
    if files:
        for f in files:
            file_list.append(f)

print(len(file_list))


difference = pd.DataFrame()
print(len(set(cik_list['file_match'][0:50000])))


difference['file_match'] = list(set(file_list) - set(cik_list['file_match'][0:50000]) )

print(len(difference['file_match']))
print(difference)

# for i in range(0, len(difference)):
#     if os.path.exists(base_path + str(difference['file_match'][i])):
#         os.remove(base_path + difference['file_match'][i])
#     else:
#         print('no such file')
#
# source = cik_list['file_match']
# from collections import defaultdict
#
#
# def list_duplicates(seq):
#     tally = defaultdict(list)
#     for i, item in enumerate(seq):
#         tally[item].append(i)
#     return ((key, locs) for key, locs in tally.items()
#             if len(locs) > 1)
#
#
# for dup in sorted(list_duplicates(source)):
#     print(dup)
#
not_downloaded_files = pd.merge(difference, cik_list, how='left', left_on='file_match', right_on='file_match')

print(not_downloaded_files)

# for i in range(0, 50000):
#     cik = cik_list['CIK'][i]
#     form = cik_list['form_type'][i]
#     date = cik_list['fdate'][i]
#     code_1 = cik_list['filename'][i].split('-')[-1]
#     code_2 = cik_list['filename'][i].split('-')[-2]
#     code_3 = cik_list['filename'][i].split('-')[-3].split('/')[-1]
#     file_url = 'https://www.sec.gov/Archives/' + cik_list['filename'][i]
#     doc_name = str(cik) + '_' + form + '_' + str(date) + '_' + code_3 + '_' + code_2 + '_' + code_1
#
#     r = requests.get(file_url)
#     data = r.text
#     path = os.path.join(base_path,
#                         doc_name)
#
#     with open(path, "ab") as f:
#         f.write(data.encode('ascii', 'ignore'))








