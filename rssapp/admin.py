from django.contrib import admin

# Register your models here.
from .models import RssLink

class RssLinkAdmin(admin.ModelAdmin):
    class Meta:
        model = RssLink

admin.site.register(RssLink,RssLinkAdmin)