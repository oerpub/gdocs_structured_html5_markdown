# -*- coding: utf8 -*-
"""This module converts Google Docs HTML to structured HTML5"""

import sys
import os
import re
import urllib2
import subprocess
import libxml2
import libxslt
from tidylib import tidy_document
from xhtmlpremailer import xhtmlPremailer
from lxml import etree
import magic
from functools import partial
import html2text

CURRENT_DIR = os.path.dirname(__file__)

XHTML_ENTITIES = os.path.join(
    CURRENT_DIR, 'xslt_gdocs_structured_html', 'catalog_xhtml', 'catalog.xml')

download_files_from_google = False

gmath_latex = []


def tidy2xhtml(html):
    """Use HTML Tidy to tidy up Google Docs HTML"""
    xhtml, errors = tidy_document(html, options={
        'output-xhtml': 1,     # XHTML instead of HTML4
        'indent': 0,           # Don't use indent, add's extra linespace or linefeeds which are big problems
        'tidy-mark': 0,        # No tidy meta tag in output
        'wrap': 0,             # No wrapping
        'alt-text': '',        # Help ensure validation
        'doctype': 'strict',   # Little sense in transitional for tool-generated markup...
        'force-output': 1,     # May not get what you expect but you will get something
        'numeric-entities': 1, # remove HTML entities like e.g. nbsp
        'clean': 1,            # remove
        'bare': 1,
        'word-2000': 1,
        'drop-proprietary-attributes': 1,
        'enclose-text': 1,     # enclose text in body always with <p>...</p>
        'logical-emphasis': 1  # transforms <i> and <b> text to <em> and <strong> text
        })
    # TODO: parse errors from tidy process
    return xhtml, {}


def premail(xhtml):
    """Move CSS from stylesheet inside the tags itself.

    BTW: Premailer does this usually for old email clients.
    Use a special XHTML Premailer which does not destroy the XML structure.
    """
    premailer = xhtmlPremailer(xhtml)
    premailed_xhtml = premailer.transform()
    return premailed_xhtml, {}


def tex2mathml(xml):
    """Use Blahtex transformation from TeX to XML.

    http://gva.noekeon.org/blahtexml/
    """
    # Do not run blahtex if we are not on Linux or Mac!
    if os.name == 'posix':
        xpathFormulars = etree.XPath('//nohtml:tex[@tex]', namespaces={'nohtml':'http://nohtml'})
        formularList = xpathFormulars(xml)
        for formular in formularList:
            strTex = urllib2.unquote(formular.get('tex'))
            #TODO: Ubuntu has 'blahtexml', when compiled by yourself the binary name will be 'blahtex'. This needs to be more dynamically!
            strCmdBlahtex = ['blahtexml','--mathml']
            # run the program with subprocess and pipe the input and output to variables
            p = subprocess.Popen(strCmdBlahtex, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
            #TODO: Catch blahtex processing errors!
            strMathMl, strErr = p.communicate(strTex) # set STDIN and STDOUT and wait till the program finishes
            mathMl = etree.fromstring(strMathMl)
            annotation = etree.Element("annotation", encoding="math/tex")
            annotation.text = strTex
            mathMl.append(annotation)
            formular.append(mathMl)
            # How blahtex output looks like. Needs further processing (semantics, enclose all math into one tag, move annotation to right position)
            # <blahtex>
            # <mathml>
            # <markup>
            # <mrow><mi>x</mi><mo lspace="0.278em" rspace="0.278em">=</mo><msup><mi>d</mi><mn>2</mn></msup></mrow>
            # </markup>
            # </mathml>
            # <annotation encoding="math/tex">x={d}^{2}</annotation>
            # </blahtex>
    else:
        print 'Error: Math will not be converted! Blahtex is only available on Linux!'
    return xml

def gmath2mathml(xml):
    # Do not run blahtex if we are not on Linux or Mac!
    if os.name == 'posix':
        xpathFormulars = etree.XPath('//nohtml:gmath', namespaces={'nohtml':'http://nohtml'})
        formularList = xpathFormulars(xml)
        for position, formular in enumerate(formularList):
            try:
                strTex = gmath_latex[position]
            except IndexError:
                strTex = 'KixGdocsEerror'
            #TODO: Ubuntu has 'blahtexml', when compiled by yourself the binary name will be 'blahtex'. This needs to be more dynamically!
            strCmdBlahtex = ['blahtexml','--mathml']
            # run the program with subprocess and pipe the input and output to variables
            p = subprocess.Popen(strCmdBlahtex, stdin=subprocess.PIPE, stdout=subprocess.PIPE)
            #TODO: Catch blahtex processing errors!
            strMathMl, strErr = p.communicate(strTex) # set STDIN and STDOUT and wait till the program finishes
            mathMl = etree.fromstring(strMathMl)
            annotation = etree.Element("annotation", encoding="math/tex")
            annotation.text = strTex
            mathMl.append(annotation)
            formular.append(mathMl)
    else:
        print 'Error: Math will not be converted! Blahtex is only available on Linux!'
    return xml


# Get the filename without extension form a URL
# TODO: This does not worked reliable
# def getNameFromUrl(s):
#     return os.path.splitext(urllib2.unquote(os.path.basename(urlparse(s).path)))[0]

# Downloads images from Google Docs and sets metadata for further processing
def download_images(xml):
    objects = {}    # image contents will be saved here
    xpathImages = etree.XPath('//nohtml:image', namespaces={'nohtml':'http://nohtml'})
    imageList = xpathImages(xml)
    for position, image in enumerate(imageList):
        strImageUrl = image.get('src')
        print "Download GDoc Image: " + strImageUrl  # Debugging output
        # TODO: This try finally block does not work when we have e.g. no network!!!
        try:
            strImageContent = urllib2.urlopen(strImageUrl).read()
            # get Mime type from image
            strImageMime = magic.whatis(strImageContent)
            # only allow this three image formats
            if strImageMime in ('image/png', 'image/jpeg', 'image/gif'):
                image.set('mime-type', strImageMime)
                strImageName = "gd-%04d" % (position + 1)  # gd0001.jpg
                if strImageMime == 'image/jpeg':
                    strImageName += '.jpg'
                elif strImageMime == 'image/png':
                    strImageName += '.png'
                elif strImageMime == 'image/gif':
                    strImageName += '.gif'
                #Note: SVG is currently (2012-03-08) not supported by GDocs.
                image.text = strImageName
                # add contents of image to object
                objects[strImageName] = strImageContent

                # just for debugging
                #myfile = open(strImageName, "wb")
                #myfile.write(strImageContent)
                #myfile.close
        finally:
            pass
    return xml, objects

# Initialize libxml2, e.g. transforming XHTML entities to valid XML
def init_libxml2(xml):
    libxml2.loadCatalog(XHTML_ENTITIES)
    libxml2.lineNumbersDefault(1)
    libxml2.substituteEntitiesDefault(1)
    return xml, {}

def xslt(xsl, xml):
    # XSLT transformation with libxml2
    xsl = os.path.join(CURRENT_DIR, 'xslt_gdocs_structured_html', xsl) # TODO: Needs a cleaner solution
    style_doc = libxml2.parseFile(xsl)
    style = libxslt.parseStylesheetDoc(style_doc)
    # doc = libxml2.parseFile(afile)) # another way, just for debugging
    doc = libxml2.parseDoc(xml)
    result = style.applyStylesheet(doc, None)
    # style.saveResultToFilename(os.path.join('output', docFilename + '_xyz.xml'), result, 1) # another way, just for debugging
    xml_result = style.saveResultToString(result)
    style.freeStylesheet()
    doc.freeDoc()
    result.freeDoc()

    return xml_result, {}

def tex2mathml_transform(xml):
    # Parse XML with etree from lxml for TeX2MathML
    etree_xml = etree.fromstring(xml)
    # Convert TeX to MathML with Blahtex
    etree_xml = tex2mathml(etree_xml)
    etree_xml = gmath2mathml(etree_xml)
    return etree.tostring(etree_xml), {}

# Download Google Docs Images
def image_puller(xml):
    if download_files_from_google:
      image_objects = {}
      etree_xml = etree.fromstring(xml)
      etree_xml, image_objects = download_images(etree_xml)
      return etree.tostring(etree_xml), image_objects
    else:
      return xml, {}

def extract_math_from_kix(kix_content):
    # find all gmath expressions
    encoded_math_list = re.findall("https?:\/\/api\.gmath\.guru\/cgi-bin\/gmath\?(.*)\f.*", kix_content)
    latex_list = []
    # decode url encoded math to UTF-8 string
    for encoded_math in encoded_math_list:
        decoded_math = urllib2.unquote(encoded_math).decode('utf8')
        # remove dpi settings for blahtex
        cleaned_math = re.sub(r'\\dpi{\d+}', '', decoded_math)
        latex_list.append(cleaned_math)
    return latex_list

# result from every step in pipeline is a string (xml) + object {...}
# explanation of "partial" : http://stackoverflow.com/q/10547659/756056
TRANSFORM_PIPELINE = [
    tidy2xhtml,                                             # 1
    premail,                                                # 2
    init_libxml2,                                           # 3
    partial(xslt, 'pass0_gdocs_headers.xsl'),               # 4
    partial(xslt, 'pass1_new_min_header_level.xsl'),        # 5
    partial(xslt, 'pass2_xhtml_gdocs_headers.xsl'),         # 6
    partial(xslt, 'pass3_gdocs_listings.xsl'),              # 7
    partial(xslt, 'pass4_gdocs_listings.xsl'),              # 8
    partial(xslt, 'pass5_gdocs_listings.xsl'),              # 9
    partial(xslt, 'pass6_gdocs2html5.xsl'),                 # 11
    tex2mathml_transform,                                   # 12
    image_puller,                                           # 13
    partial(xslt, 'pass7_nohtml_postprocessing.xsl'),       # 14
]

# the function which is called from outside to start transformation
def gdocs_to_html5(content, kixcontent=None, bDownloadImages=False, debug=False):
    global gmath_latex
    global download_files_from_google
    if (kixcontent==None):
        gmath_latex = []
    else:
        gmath_latex = extract_math_from_kix(kixcontent)
    objects = {}
    xml = content
    download_files_from_google = bDownloadImages
    # write input file to debug dir
    if debug: # create for each pass an output file
        filename = os.path.join(CURRENT_DIR, 'gdocs_debug', 'input.htm') # TODO: needs a timestamp or something
        f = open(filename, 'w')
        f.write(xml)
        f.flush()
        f.close()
    for i, transform in enumerate(TRANSFORM_PIPELINE):
        newobjects = {}
        xml, newobjects = transform(xml)
        if len(newobjects) > 0:
            objects.update(newobjects) # copy newobjects into objects dict
        print "== Pass: %02d | Function: %s | Objects: %s ==" % (i+1, transform, objects.keys())
        if debug: # create for each pass an output file
            filename = os.path.join(CURRENT_DIR, 'gdocs_debug', 'pass%02d.xml' % (i+1)) # TODO: needs a timestamp or something
            f = open(filename, 'w')
            f.write(xml)
            f.flush()
            f.close()
    # write objects to debug dir
    if debug:
        for image_filename, image in objects.iteritems():
            image_filename = os.path.join(CURRENT_DIR, 'gdocs_debug', image_filename) # TODO: needs a timestamp or something
            image_file = open(image_filename, 'wb') # write binary, important!
            try:
                image_file.write(image)
                image_file.flush()
            finally:
                image_file.close()
    return xml, objects

def html5_to_markdown(html):
    h = html2text.HTML2Text()
    h.ignore_links = False
    h.skip_internal_links = False
    h.unicode_snob = True
    markdown = h.handle(html)
    return markdown

if __name__ == "__main__":
    f = open(sys.argv[1])
    content = f.read()
    #print gdocs_to_cnxml(content)
    gdocs_to_cnxml(content, bDownloadImages=True, debug=True)
