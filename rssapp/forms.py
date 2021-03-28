from django import forms
from .models import RssLink

class RssLinkForm(forms.Form):
    link = forms.CharField(required=True)

class EmailRssForm(forms.Form):
    email_field = forms.EmailField(required=True)