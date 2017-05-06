from flask import render_template, flash, redirect
from app import app
from .forms import GdocsForm
#from dummy_get_gdocs_from_url import get_gdocs_from_url
from get_gdocs_from_url import get_gdocs_from_url
from gdocs2html5 import gdocs_to_html5, html5_to_markdown
from zipfile import ZipFile
import time

url = ''
transformed = ''
transform_markdown = ''
zipfilename = ''


@app.route('/', methods=['GET', 'POST'])
def index():
    global url
    global transformed
    global transform_markdown
    global zipfilename
    form = GdocsForm()
    user = {'nickname': 'Marvin'}  # fake user
    if form.validate_on_submit():
        flash('Converting %s' % form.gdocs.data)
        url = form.gdocs.data
        gdocs_dirty_html, kix = get_gdocs_from_url(url)
        transformed, objects = gdocs_to_html5(
            gdocs_dirty_html, kixcontent=None, bDownloadImages=True, debug=True)
        transform_markdown = html5_to_markdown(transformed)
        zipfilename = 'gdocshtml5-'+ time.strftime("%Y%m%d-%H%M%S") + '.zip'
        with ZipFile(file='./app/static/' + zipfilename, mode='w') as myzip:
            myzip.writestr('html5.htm', transformed)
            myzip.writestr('markdown.md', transform_markdown.encode("UTF-8"))
            for image_filename, image in objects.iteritems():
                myzip.writestr(image_filename, image)
        myzip.close()
        return redirect('/')

    return render_template('index.html',
                           title='Home',
                           form=form,
                           gdocshtml=transformed,
                           markdown=transform_markdown,
                           zipfile=zipfilename)
