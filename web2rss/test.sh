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
 export DEBUG_ARTICLE=https://hk.news.yahoo.com/%E9%99%B3%E5%98%89%E8%8E%89%E6%8C%91%E6%88%B0sm%E6%88%B2%E5%8A%9B%E4%BF%9D%E4%B8%89%E9%BB%9E-214500217.html


env DEBUG=1 bash rss-nt.sh

