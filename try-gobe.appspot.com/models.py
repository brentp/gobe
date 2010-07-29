from google.appengine.ext import db

class Annotation(db.Model):
    anno_id = db.StringProperty() # hash of content
    title = db.StringProperty()
    author = db.UserProperty()
    content = db.TextProperty()
    date = db.DateTimeProperty(auto_now=True)
