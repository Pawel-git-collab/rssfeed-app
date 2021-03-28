from django.db import models


class RssLink(models.Model):
    link = models.CharField(max_length=100)
    added = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return str(self.link)