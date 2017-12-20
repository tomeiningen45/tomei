 export DEBUG_ADAPTERS=
 export DEBUG_ARTICLE=
#export DEBUG_MAX_ARTICLES=
#export DEBUG_MAX_ARTICLES=20
#export DEBUG_MAX_DOWNLOADS=20
 
#----------------------------------------------------------------------
# Tests for specific sites
#----------------------------------------------------------------------

#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} reuters"
 export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoohk"

#----------------------------------------------------------------------
# Tests for specific article -- if non-empty, must be exactly one URL,
# and ${DEBUG_ADAPTERS} must be a single entry which can handle the URL
#----------------------------------------------------------------------

#export DEBUG_ARTICLE=
#export DEBUG_ARTICLE="http://feeds.reuters.com/~r/reuters/topNews/~3/Svyx0NMhLP8/-idUSKBN1EA0OO"
 export DEBUG_ARTICLE=https://hk.news.yahoo.com/%E7%97%A0%E7%97%9B%E8%97%A5%E5%B8%83-%E7%B6%A0%E6%B2%B9%E7%B2%BE-%E5%A4%9A%E6%AC%BE%E5%9C%8B%E6%B0%91%E8%97%A5%E5%93%81-%E8%A6%81%E6%BC%B2%E5%83%B9%E5%95%A6-023545169.html






#----------------------------------------------------------------------
env DEBUG=1 bash rss-nt.sh

