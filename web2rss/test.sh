export DEBUG_ADAPTERS=
export DEBUG_ARTICLE=

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

env DEBUG=1 bash rss-nt.sh

