 export DEBUG_ADAPTERS=
 export DEBUG_ARTICLE=
#export DEBUG_MAX_ARTICLES=
#export DEBUG_MAX_ARTICLES=20
#export DEBUG_MAX_DOWNLOADS=20
 
#----------------------------------------------------------------------
# Tests for specific sites
#----------------------------------------------------------------------

#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} reuters"
#export DEBUG_ADAPTERS="${DEBUG_ADAPTERS} yahoohk"

#----------------------------------------------------------------------
# Tests for specific article -- if non-empty, must be exactly one URL,
# and ${DEBUG_ADAPTERS} must be a single entry which can handle the URL
#----------------------------------------------------------------------

#export DEBUG_ARTICLE=
#export DEBUG_ARTICLE="http://feeds.reuters.com/~r/reuters/topNews/~3/Svyx0NMhLP8/-idUSKBN1EA0OO"
#export DEBUG_ARTICLE=https://hk.news.yahoo.com/%E5%9B%9B%E5%B7%9D%E7%96%91%E5%85%87%E6%94%B9%E5%AB%81%E6%B8%AF%E4%BA%BA-%E9%9B%A2%E5%A9%9A%E7%95%B6%E6%8C%89%E6%91%A9%E5%A5%B3-214500548.html


env DEBUG=1 bash rss-nt.sh

