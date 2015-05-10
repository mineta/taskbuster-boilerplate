# -*- coding: utf-8 -*-
from django.conf.urls import include, url
from django.contrib import admin
from django.conf.urls.i18n import i18n_patterns
from .views import home, home_files

urlpatterns = [
    url(r'^(?P<filename>(robots.txt)|(humans.txt))$',
        home_files, name='home-files'),
    url(r'i18n/', include('django.conf.urls.i18n')),
]

urlpatterns += i18n_patterns(
    url(r'^$', home, name='home'),
    url(r'^admin/', include(admin.site.urls)),
)
