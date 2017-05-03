from flask_wtf import FlaskForm
from wtforms import StringField, BooleanField
from wtforms.validators import DataRequired

class GdocsForm(FlaskForm):
    gdocs = StringField('gdocs', validators=[DataRequired()])