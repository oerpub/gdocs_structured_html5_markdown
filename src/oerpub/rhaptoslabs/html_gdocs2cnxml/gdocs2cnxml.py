#! /usr/bin/env python
import sys
import os
import urllib2
#from urlparse import urlparse
import subprocess
import libxml2
import libxslt
from tidylib import tidy_document
from xhtmlpremailer import xhtmlPremailer
from lxml import etree
import magic
from functools import partial

current_dir = os.path.dirname(__file__)

XHTML_ENTITIES = os.path.join(current_dir, 'www', 'catalog_xhtml', 'catalog.xml')

# Tidy up the Google Docs HTML Soup
def tidy2xhtml(html):
    # HTML Tidy
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

# Move CSS from stylesheet inside the tags with. BTW: Premailer does this usually for old email clients.
# Use a special XHTML Premailer which does not destroy the XML structure.
def premail(xhtml):
    premailer = xhtmlPremailer(xhtml)
    premailed_xhtml = premailer.transform()
    return premailed_xhtml, {}

# Use Blahtex transformation from TeX to XML. http://gva.noekeon.org/blahtexml/
def tex2mathml(xml):
    # Do not run blahtex if we are not on Linux!
    if os.name == 'posix':
        xpathFormulars = etree.XPath('//cnxtra:tex[@tex]', namespaces={'cnxtra':'http://cnxtra'})
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
    xpathImages = etree.XPath('//cnxtra:image', namespaces={'cnxtra':'http://cnxtra'})
    imageList = xpathImages(xml)
    for position, image in enumerate(imageList):
        strImageUrl = image.get('src')
        print "Download GDoc Image: " + strImageUrl  # Debugging output
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
            strAlt = image.get('alt')
            if not strAlt:
                image.set('alt', strImageUrl) # getNameFromUrl(strImageUrl)) # TODO: getNameFromUrl does not work reliable
            image.text = strImageName
            # add contents of image to object
            objects[strImageName] = strImageContent

            # just for debugging
            #myfile = open(strImageName, "wb")
            #myfile.write(strImageContent)
            #myfile.close
    return xml, objects

# Initialize libxml2, e.g. transforming XHTML entities to valid XML
def init_libxml2(xml):
    libxml2.loadCatalog(XHTML_ENTITIES)
    libxml2.lineNumbersDefault(1)
    libxml2.substituteEntitiesDefault(1)
    return xml, {}

def xslt(xsl, xml):
    # XSLT transformation with libxml2
    xsl = os.path.join(current_dir, 'www', xsl) # TODO: Needs a cleaner solution
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
    return etree.tostring(etree_xml), {}

# Download Google Docs Images
def image_puller(xml):   
    image_objects = {}
    etree_xml = etree.fromstring(xml)
    #if bDownloadImages:
    etree_xml, image_objects = download_images(etree_xml)
    return xml, image_objects
    
# result from every step in pipeline is a string (xml) + object {...}
# explanation of "partial" : http://stackoverflow.com/q/10547659/756056
TRANSFORM_PIPELINE = [
    tidy2xhtml,
    premail,
    init_libxml2,
    partial(xslt, 'pass1_gdocs_headers.xsl'),
    partial(xslt, 'pass2_xhtml_gdocs_headers.xsl'),
    partial(xslt, 'pass3_gdocs_listings.xsl'),
    partial(xslt, 'pass4_gdocs_listings.xsl'),
    partial(xslt, 'pass5_gdocs_listings.xsl'),
    partial(xslt, 'pass5_part2_gdocs_red2cnxml.xsl'),
    partial(xslt, 'pass6_gdocs2cnxml.xsl'),
    tex2mathml_transform,
    image_puller,
    partial(xslt, 'pass7_cnxml_postprocessing.xsl'),
    partial(xslt, 'pass8_cnxml_id-generation.xsl'),
    partial(xslt, 'pass9_cnxml_postprocessing.xsl')
]

# the function which is called from outside to start transformation
def gdocs_to_cnxml(content, bDownloadImages=False, debug=False):
    objects = {}
    xml = content
    for i, transform in enumerate(TRANSFORM_PIPELINE):
        newobjects = {}
        xml, newobjects = transform(xml)
        if len(newobjects) > 0:
            objects.update(newobjects) # copy newobjects into objects dict
        print "== Pass: %f2. | Function: %s | Objects: %s ==" % (i+1, transform, objects.keys())
    
    return xml, objects

if __name__ == "__main__":
    f = open(sys.argv[1])
    content = f.read()
    #print gdocs_to_cnxml(content)
    gdocs_to_cnxml(content, bDownloadImages=True, debug=True)
