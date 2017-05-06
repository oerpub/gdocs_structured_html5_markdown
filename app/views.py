from flask import render_template, flash, redirect
from app import app
from .forms import GdocsForm
#from dummy_get_gdocs_from_url import get_gdocs_from_url
from get_gdocs_from_url import get_gdocs_from_url
from gdocs2html5 import gdocs_to_html5
from zipfile import ZipFile

url = ''
transformed = ''


@app.route('/', methods=['GET', 'POST'])
def index():
    global url
    global transformed
    form = GdocsForm()
    user = {'nickname': 'Marvin'}  # fake user
    if form.validate_on_submit():
        flash('Converting %s' % form.gdocs.data)
        url = form.gdocs.data
        gdocs_dirty_html, kix = get_gdocs_from_url(url)
        transformed, objects = gdocs_to_html5(
            gdocs_dirty_html, kixcontent=None, bDownloadImages=True, debug=True)
        flash(transformed)
        for o in objects:
            print o
        with ZipFile(file='./app/static/test.zip', mode='w') as myzip:
            myzip.writestr('gdocs_structured_html5.htm', transformed)
        myzip.close()
        return redirect('/')

    return render_template('index.html',
                           title='Home',
                           form=form,
                           gdocshtml=transformed)
