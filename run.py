# -*- coding: utf8 -*-
"""Flask web server"""

from app import app

# fix flask utf-8 problems http://stackoverflow.com/a/14919377/756056
import sys
reload(sys)
sys.setdefaultencoding('utf-8')

app.run(debug=True,
        host=app.config.get("HOST", "localhost"),
        port=app.config.get("PORT", 9000)
        )
