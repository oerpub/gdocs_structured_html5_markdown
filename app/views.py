from flask import render_template, flash, redirect
from app import app
from .forms import GdocsForm
from dummy_get_gdocs_from_url import get_gdocs_from_url
from gdocs2html5 import gdocs_to_html5

url = ''
transformed = ''

@app.route('/', methods=['GET', 'POST'])
def index():
    global url
    global transformed
    form = GdocsForm()
    user = {'nickname': 'Marvin'}  # fake user
    if form.validate_on_submit():
        flash('Converting %s' % form.gdocs.data )
        url = form.gdocs.data
        gdocs_dirty_html, kix = get_gdocs_from_url(url)
        transformed, objects = gdocs_to_html5(gdocs_dirty_html, kixcontent=None, bDownloadImages=False, debug=False)
        return redirect('/')

    return render_template('index.html',
                           title='Home',
                           form=form,
                           gdocshtml=transformed)