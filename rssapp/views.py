import feedparser
import requests
from django.shortcuts import render
from .models import RssLink
from .forms import RssLinkForm, EmailRssForm

# Create your views here.
def home(request):

    form = RssLinkForm(request.POST or None)
    if form.is_valid():
        link = form.cleaned_data['link']
        rss_link = RssLink(link=link)
        rss_link.save()

    rsslinks = RssLink.objects.all()
    #rsslinks = ["https://wydarzenia.interia.pl/feed", "https://surfing-waves.com/newsrss.xml"]

    entries = ""

    for rsslink in rsslinks:
        news_feeds = feedparser.parse(str(rsslink))
        for news_feed in news_feeds.entries:
            #tytuł + link
            link = news_feed.link.replace('"', "'")
            title = news_feed.title.replace('"', "'")
            description = news_feed.description.replace('"', "'")
            entries = f"{entries}<a href='{link}'><h4>{title}</h4></a>"
            #opis
            if "<p>" in description:
                entries = f"{entries}{description}"
            else:
                entries = f"{entries}<p>{description}</p>"
            #odstep
            entries = f"{entries}<br>"

    context = {'rsslinks': rsslinks, 'entries': entries, 'form': form}

    form = EmailRssForm(request.POST or None)
    if form.is_valid():
        email_field = form.cleaned_data['email_field']
        requests.post(
        "https://api.mailgun.net/v3/sandbox8f022652f57a4722897b33fe8575dac9.mailgun.org/messages",
        auth = ("api", "e810cf99c6f043d42aeb32f2f369bf6f-29561299-b43d3a36"),
        data = {"from": "mailgun@sandbox8f022652f57a4722897b33fe8575dac9.mailgun.org",
                "to": [email_field],
                "subject": "RssFeedApp with Email - News update",
                "html": entries})

    return render(request, 'home.html', context=context)