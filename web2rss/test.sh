# NOTES:
#
# output is in /opt/local/www/apache2/html/webrss

 export DEBUG_ADAPTERS=
 export DEBUG_ARTICLE=

#Number of articles to store in the xml file
#export DEBUG_MAX_ARTICLES=
#export DEBUG_MAX_ARTICLES=60
 export DEBUG_MAX_ARTICLES=20

#Number of articles to download from the web site
#export DEBUG_MAX_DOWNLOADS=20
 export DEBUG_MAX_DOWNLOADS=20

# Set the following to exit after the first site has finished writing to db
 export DEBUG_NO_LOOPS=1
#----------------------------------------------------------------------
# Tests for specific sites
#----------------------------------------------------------------------

#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} reuters"  (no more RSS feed from reuters)
 export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} bleacher"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} 6park_forum_mil"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} 6park"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoohk"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoojp_main"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoojp_mag"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoojp_sci"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} nhk"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} gigazine"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} craigslist"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} hatelabo"

#----------------------------------------------------------------------
# Tests for specific article -- if non-empty, must be exactly one URL,
# and ${DEBUG_ADAPTERS} must be a single entry which can handle the URL
#----------------------------------------------------------------------

#export DEBUG_ARTICLE=https://gigazine.net/news/20210115-pirate-bay-founder-parler-embarrassing/
#export DEBUG_ARTICLE=https://news.yahoo.co.jp/articles/058bc222b5539e9d4d7f2a6743ed2b4d974c87de
#export DEBUG_ARTICLE=https://sfbay.craigslist.org/sfc/ctd/d/2012-ford-e350-extended-15-passenger/7257286046.html
#export DEBUG_ARTICLE=https://sfbay.craigslist.org/eby/cto/d/vallejo-2009-hyundai-sonata-gls-speed/7258436465.html
#export DEBUG_ARTICLE=https://headlines.yahoo.co.jp/article?a=20210108-74127209-business-bus_all
#export DEBUG_ARTICLE=https://news.yahoo.co.jp/articles/467b76408a96d9f61d8889e693efc8474186f461
#export DEBUG_ARTICLE=
#export DEBUG_ARTICLE="http://feeds.reuters.com/~r/reuters/topNews/~3/Svyx0NMhLP8/-idUSKBN1EA0OO"
#export DEBUG_ARTICLE=https://tw.travel.yahoo.com/news/%E7%B4%90%E8%A5%BF%E8%98%AD%E8%87%AA%E7%94%B1%E8%A1%8C-38-000%E5%85%83%E7%92%B0%E9%81%8A%E7%B4%90%E8%A5%BF%E8%98%AD-%E6%A9%9F%E7%A5%A8-%E9%A3%9F%E5%AE%BF-071721925.html
#export DEBUG_ARTICLE=http://bleacherreport.com/articles/2752850-lavar-ball-lakers-dont-want-to-play-for-luke-walton-lonzo-looked-disgusted

#export DEBUG_ARTICLE='https://club.6parker.com/military/index.php?app=forum&act=threadview&tid=15170548'

#export DEBUG_ARTICLE=https://bleacherreport.com/articles/2816345-lebron-james-calls-out-nba-refs-after-late-lonzo-ball-foul-on-russell-westbrook

#export DEBUG_ARTICLE=https://bleacherreport.com/articles/10065118-kevin-durant-steph-curry-zion-injury-replacements-revealed-for-nba-all-star-game
#----------------------------------------------------------------------
if test ! -f FilterEmoji.class; then
    javac FilterEmoji.java || exit 1
fi

env DEBUG=1 bash rss-nt.sh

