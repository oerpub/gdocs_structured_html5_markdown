from flask import render_template, flash, redirect
from app import app
from .forms import GdocsForm
from testbed_local import main

url = ''

@app.route('/', methods=['GET', 'POST'])
def index():
    global url
    form = GdocsForm()
    user = {'nickname': 'Marvin'}  # fake user
    if form.validate_on_submit():
        flash('Converting %s' % form.gdocs.data )
        url = form.gdocs.data
        main()
        return redirect('/')

    return render_template('index.html',
                           title='Home',
                           form=form,
                           gdocshtml=url)