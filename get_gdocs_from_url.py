'''
Get Google Docs HTML and KIX content from URL

@author: Marvin Reimer
'''

import sys
import os
import subprocess
import re
import shutil
import httplib2


def _get_doc_id_from_url(url):
    match_doc_id = re.match(r'^.*docs\.google\.com/document/d/([^/]+).*$', url)
    print match_doc_id
    if match_doc_id:
        return match_doc_id.group(1)
    return ''

def _match_localhost(url):
    ''' for debugging only '''
    result = False
    match_doc_id = re.match(r'^.*(localhost|127\.0\.0\.1).*$', url)
    if match_doc_id:
        result = True
    return result

def _download_from_url(url):
    ''' for debugging only '''
    http = httplib2.Http()
    http.follow_redirects = False
    resp, html = http.request(url)
    return html

def _get_html_from_id(doc_id):
    http = httplib2.Http()
    http.follow_redirects = False
    html = ''
    try:
        plain_html_url = 'https://docs.google.com/document/d/%s/export?format=html&confirm=no_antivirus' % doc_id
        resp, html = http.request(plain_html_url)
    except:
        print "Error: Failed to download Google Docs HTML"
    return html


def _get_kix_from_id(doc_id):
    http = httplib2.Http()
    http.follow_redirects = False
    kix = ''
    try:
        kix_url = 'https://docs.google.com/feeds/download/documents/export/Export?doc_id=%s&exportFormat=kix' % doc_id
        resp, kix = http.request(kix_url)
    except:
        print "Error: Failed to download Google Docs Kix"
    return kix


def get_gdocs_from_url(url):
    doc_id = _get_doc_id_from_url(url)
    if len(doc_id)>1:
        html = _get_html_from_id(doc_id)
        kix = _get_kix_from_id(doc_id)
        return html, kix
    elif _match_localhost(url):     # for debugging only
        html = _download_from_url(url)
        return html, ''
    else:
        return '', ''