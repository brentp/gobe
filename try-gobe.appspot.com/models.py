from google.appengine.ext import db

class Annotation(db.Model):
    anno_id = db.StringProperty() # hash of content
    title = db.StringProperty()
    author = db.UserProperty()
    content = db.TextProperty()
    date = db.DateTimeProperty(auto_now=True)

    format = db.StringProperty(choices=set(("gff", "bed", "gobe", "blast")))

    # store the anno_ids of the plots associated with this one.
    bar_hist_ids = db.StringListProperty()


    def get_bar_hists(self):
        bhs = []
        for anno_id in self.bar_hist_ids:
            bhs.append(Annotation.all().filter('anno_id = ', anno_id).get())
        return bhs

    @classmethod
    def by_anno_id(self, anno_id):
        return Annotation.all().filter('anno_id =', anno_id).get()
