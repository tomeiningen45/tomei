# NOTES:
#
# output is in /opt/local/www/apache2/html/webrss

 export DEBUG_ADAPTERS=
 export DEBUG_ARTICLE=

#Number of articles to store in the xml file
#export DEBUG_MAX_ARTICLES=
#export DEBUG_MAX_ARTICLES=60
 export DEBUG_MAX_ARTICLES=80

#Number of articles to download from the web site
#export DEBUG_MAX_DOWNLOADS=20
 export DEBUG_MAX_DOWNLOADS=20

# Set the following to exit after the first site has finished writing to db
 export DEBUG_NO_LOOPS=1
#----------------------------------------------------------------------
# Tests for specific sites
#----------------------------------------------------------------------

#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} reuters"  (no more RSS feed from reuters)
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} bleacher"
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
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} itmedia"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} dqn"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} fishing"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoofn"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} caranddriver"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} jiji"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} basketballking"
export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoohk"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} jalopnik"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} bringatrailer"

#----------------------------------------------------------------------
# Tests for specific article -- if non-empty, must be exactly one URL,
# and ${DEBUG_ADAPTERS} must be a single entry which can handle the URL
#----------------------------------------------------------------------

#D=https://www.caranddriver.com/news/a43698012/2024-mclaren-750s-revealed/
#D=https://www.caranddriver.com/photos/g43688888/2024-mclaren-750s-revealed-photos/
#D=https://finance.yahoo.com/news/dollar-dominance-could-way-tripolar-182500899.html
#D=https://finance.yahoo.com/news/fed-decision-apple-earnings-april-jobs-report-what-to-know-this-week-144601325.html
#D=https://finance.yahoo.com/news/oil-chaotic-selloff-worsens-7-232258587.html
#D=https://finance.yahoo.com/news/warren-buffetts-bank-account-charlie-184500727.html
#D=https://www.caranddriver.com/reviews/a43825380/2024-porsche-cayenne-s-turbo-gt-drive/
#D=https://hk.news.yahoo.com/%E6%9B%BE%E6%B7%91%E9%9B%85-030145204.html.html
#D=https://jalopnik.com/chances-of-city-killing-asteroid-impact-in-2032-upped-t-1851762206
#D=https://jalopnik.com/cheap-european-cars-are-ditching-infotainment-screens-i-1851758109
#D=https://jalopnik.com/at-15-500-is-this-2007-mini-cooper-s-a-mega-bargain-1851761170
#D=https://jalopnik.com/boeing-737-max-hits-car-in-the-middle-of-runway-during-1851762609
#D=https://jalopnik.com/plane-wrecks-sub-implosion-audio-and-boomless-superson-1851763730
#D=https://bleacherreport.com/articles/10129493-report-kevin-durant-blindsided-by-suns-warriors-trade-rumors-before-nba-deadline
#D=https://www.itmedia.co.jp/news/articles/2502/14/news159.html
#D=https://hk.news.yahoo.com/%E5%B7%9D%E6%99%AE%E7%89%B9%E4%BD%BF-%E7%BE%8E%E4%B8%8D%E6%9C%83%E5%B0%8D%E7%83%8F%E5%85%8B%E8%98%AD%E5%BC%B7%E5%8A%A0%E5%8D%94%E8%AD%B0-043502218.html
if test "$DDAA" = ""; then
    export DEBUG_ARTICLE=$D
fi
echo $DEBUG_ARTICLE
#----------------------------------------------------------------------
if test ! -f FilterEmoji.class; then
    javac FilterEmoji.java || exit 1
fi

if test "$1" = "-r"; then
    (set -x; rm -rf /var/www/html/webrss/*)
fi

env DEBUG=1 bash rss-nt.sh

