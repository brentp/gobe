from google.appengine.ext import webapp
from google.appengine.ext.webapp.util import run_wsgi_app
from google.appengine.api import users
from google.appengine.ext.webapp import template
from django.utils import simplejson
import hashlib
import utils


import os.path as op
from models import Annotation

FORMATS = ("gff3", "bed", "gobe")

template_dir = op.join(op.dirname(__file__), "templates")
def render(path, vals=None, **kwargs):
    if vals is None: vals = {}
    vals.update(kwargs)
    path = op.join(template_dir, path)
    return template.render(path, vals)

def user_stuff(uri):
    if users.get_current_user():
        url = users.create_logout_url(uri)
        url_text = 'Logout'
    else:
        url = users.create_login_url(uri)
        url_text = 'Login'
    return {'login_url': url, 'login_url_text': url_text}


class Index(webapp.RequestHandler):
    def get(self, anno_id=''):
        user = users.get_current_user()
        if anno_id == "":
            a = Annotation.all().order("-date").get()
        else:
            a = Annotation.all().filter('anno_id = ', anno_id).get()
        if a is None: a = Annotation()
        user_tmpl = user_stuff(self.request.uri)
        history = [x for x in Annotation.all().order("-date") if x.title][:12]
        name = user and user.nickname() or ""
        user_history = [x for x in Annotation.gql("WHERE author = :author", \
                              author=user) if x.title][:12] if user else None

        bar_hists = a.get_bar_hists()

        self.response.out.write(render("index.html", user_tmpl, anno_name=name, anno_id=a.anno_id or "",
                                       anno_content=a.content or "", anno_title=a.title or "",
                                       bar_hists = bar_hists,
                                       history=history, user_history=user_history))

    def post(self, unused):
        self.response.headers['Content-type'] = 'text/javascript';
        user = users.get_current_user()
        annos = self.request.get('annos', '').strip()
        format = self.request.get('format', utils.guess_format(annos))
        if not annos:
            simplejson.dumps({'status': 'fail'})
            return
        name = user and user.nickname() or ""
        title = self.request.get('title') or ""
        anno_id = hashlib.md5(annos + title).hexdigest()

        # dont save unless it's new.
        a = Annotation.gql("WHERE anno_id = :anno_id AND title = :title AND author = :author",
                           anno_id=anno_id, title=title, author=user).get()
        if a is None:
            a = Annotation(title=title, author=user, content=annos.strip(), anno_id=anno_id,
                          format=format)
            a.put()

        self.response.out.write(simplejson.dumps({'status':'success', 'anno_id': anno_id}))

class Anno(webapp.RequestHandler):
    def get(self, anno_id):
        # they can request a certain format by ending with .gobe whatever.
        import sys
        self.response.headers['Content-type'] = 'text/plain';

        if anno_id == "":
            a = Annotation.all().order("-date").get()
        elif anno_id != "all":
            a = Annotation.all().filter('anno_id = ', anno_id).get()
        if a is None: a = Annotation()
        content = a.content

        if a.format and a.format != "gobe":
            print >>sys.stderr, "converting!!!!!!!!!!!"
            content = [x.strip() for x in content.split("\n")]
            content = utils.main(content, a.format)

        self.response.out.write(content or "")

urls = (
    ('/annos/(.*)', Anno),
    ('/(.*)', Index),
)
application = webapp.WSGIApplication(urls, debug=True)


def main():
    run_wsgi_app(application)

if __name__ == "__main__":
    main()
