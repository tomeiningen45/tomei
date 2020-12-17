# NOTES:
#
# output is in /opt/local/www/apache2/html/webrss

 export DEBUG_ADAPTERS=
 export DEBUG_ARTICLE=
#export DEBUG_MAX_ARTICLES=
 export DEBUG_MAX_ARTICLES=3
#export DEBUG_MAX_DOWNLOADS=20

# Set the following to exit after the first site has finished writing to db
 export DEBUG_NO_LOOPS=1
#----------------------------------------------------------------------
# Tests for specific sites
#----------------------------------------------------------------------

#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} reuters"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} bleacher"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} 6park_forum_mil"
 export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoohk"

#----------------------------------------------------------------------
# Tests for specific article -- if non-empty, must be exactly one URL,
# and ${DEBUG_ADAPTERS} must be a single entry which can handle the URL
#----------------------------------------------------------------------

#export DEBUG_ARTICLE=
#export DEBUG_ARTICLE="http://feeds.reuters.com/~r/reuters/topNews/~3/Svyx0NMhLP8/-idUSKBN1EA0OO"
#export DEBUG_ARTICLE=https://tw.travel.yahoo.com/news/%E7%B4%90%E8%A5%BF%E8%98%AD%E8%87%AA%E7%94%B1%E8%A1%8C-38-000%E5%85%83%E7%92%B0%E9%81%8A%E7%B4%90%E8%A5%BF%E8%98%AD-%E6%A9%9F%E7%A5%A8-%E9%A3%9F%E5%AE%BF-071721925.html
#export DEBUG_ARTICLE=http://bleacherreport.com/articles/2752850-lavar-ball-lakers-dont-want-to-play-for-luke-walton-lonzo-looked-disgusted

#export DEBUG_ARTICLE='https://club.6parker.com/military/index.php?app=forum&act=threadview&tid=15170548'

#export DEBUG_ARTICLE=https://bleacherreport.com/articles/2816345-lebron-james-calls-out-nba-refs-after-late-lonzo-ball-foul-on-russell-westbrook

#export DEBUG_ARTICLE=http://bleacherreport.com/articles/2752444-jordan-bell-discusses-scuffles-with-salah-mejri-devin-harris-vs-mavericks
#----------------------------------------------------------------------
env DEBUG=1 bash rss-nt.sh

