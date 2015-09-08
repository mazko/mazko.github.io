#!/usr/bin/env python
# -*- coding: utf-8 -*- #
from __future__ import unicode_literals

AUTHOR = u'Oleg Mazko'
SITENAME = u'&#9996; Все Буде Добре &#9825;'
SITEURL = 'http://mazko.github.io'
DISQUS_SITENAME = 'mazko'

PATH = 'content'

TIMEZONE = 'Europe/Paris'

DEFAULT_LANG = u'ru'

#THEME='simple-bootstrap'

# Feed generation is usually not desired when developing
FEED_ALL_ATOM = None
CATEGORY_FEED_ATOM = None
TRANSLATION_FEED_ATOM = None
AUTHOR_FEED_ATOM = None
AUTHOR_FEED_RSS = None

# Blogroll
LINKS = (('Pelican', 'http://getpelican.com/'),
         ('Python.org', 'http://python.org/'),
         ('Jinja2', 'http://jinja.pocoo.org/'),)

# Social widget
SOCIAL = (('github', 'http://github.com/mazko'),
          ('linkedin', 'http://linkedin.com/in/mazko'),
          ('stackoverflow', 'http://stackoverflow.com/users/281102/oleg-mazko'),)

GITHUB_URL = 'http://github.com/mazko'

DEFAULT_PAGINATION = 5

ARTICLE_URL = 'blog/posts/{date:%Y}/{date:%m}/{date:%d}/{slug}/'
ARTICLE_SAVE_AS = 'blog/posts/{date:%Y}/{date:%m}/{date:%d}/{slug}/index.html'

PAGE_URL = 'blog/pages/{slug}/'
PAGE_SAVE_AS = 'blog/pages/{slug}/index.html'

YEAR_ARCHIVE_SAVE_AS = 'blog/articles/{date:%Y}/index.html'
MONTH_ARCHIVE_SAVE_AS = 'blog/articles/{date:%Y}/{date:%m}/index.html'

CATEGORY_URL = 'blog/category/{slug}/'
CATEGORY_SAVE_AS = 'blog/category/{slug}/index.html'

TAG_URL = 'blog/tag/{slug}'
TAG_SAVE_AS = 'blog/tag/{slug}/index.html'

AUTHOR_URL = 'blog/author/{slug}/'
AUTHOR_SAVE_AS = 'blog/author/{slug}/index.html'

THEME_STATIC_DIR = 'blog/theme'

ARCHIVES_URL = 'blog/archives.html'
ARCHIVES_SAVE_AS = 'blog/archives.html'

AUTHORS_URL = 'blog/authors.html'
AUTHORS_SAVE_AS = 'blog/authors.html'

CATEGORIES_URL = 'blog/categories.html'
CATEGORIES_SAVE_AS = 'blog/categories.html'

TAGS_URL = 'blog/tags.html'
TAGS_SAVE_AS = 'blog/tags.html'

STATIC_PATHS = ['posts','extra/favicon.ico']
EXTRA_PATH_METADATA = {
    'extra/favicon.ico': {'path': 'favicon.ico'}
}

ARTICLE_PATHS = ['posts']

# Uncomment following line if you want document-relative URLs when developing
#RELATIVE_URLS = True
