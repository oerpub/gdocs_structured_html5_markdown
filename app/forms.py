from flask_wtf import Form
from wtforms import StringField, BooleanField
from wtforms.validators import DataRequired

class GdocsForm(Form):
    gdocs = StringField('gdocs', validators=[DataRequired()])