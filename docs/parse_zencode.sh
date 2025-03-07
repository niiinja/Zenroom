#!/usr/bin/env zsh
# Parse and print a JSON map of Zencode calls in Given() When() Then()
# that are recognised and order them by section for documentation
#
# requires the zenroom interpreter to be installed in PATH
R=../src/lua

function _parse() {
    section=$1
    action=$2
    print "$(grep -i ''"${action}"'(' $R/zencode_${section}.lua \
	| cut -d '"' -f2 \
    | jq -Rj '. | { '"${action}"': .}' \
    | jq -s . \
    | jq -j '.| {'"${section}"': .}')"
}

tmp=`mktemp`
print $(_parse data then
		_parse simple when
		_parse coconut when) | jq -s . > $tmp
# TODO: see if transformation below needed, else just print $tmp
cat <<EOF | zenroom -a $tmp
raw_docs = JSON.decode(DATA)
tbl = { }
for k,v in ipairs(raw_docs) do
	for k,v in pairs(v) do
  	    tbl[k] = v
	end
end
write(JSON.encode(tbl))
EOF
rm $tmp
