# R Client Demo for rrest

require(RCurl)
require(RJSONIO)

body <- toJSON(
			list(n = 100)
		)

# POST and get response
h <- basicTextGatherer()
curlPerform(url = 'http://0.0.0.0:9090/randomNormal', 
			postfields = body,
			writefunction = h$update)

# See results
cat(h$value())

# Convert to R object -- this isn't working right now,
# because the first '{' is getting dropped
x <- fromJSON(h$value())


