# R Client Demo for rrest

require(RCurl)
require(RJSONIO)

body <- list(
	fun = 'randomNormal',
	params = list(
		n = 100
	)
)
body <- toJSON(body)

# POST and get response
h <- basicTextGatherer()
curlPerform(url = 'http://0.0.0.0:9090', 
			postfields = body,
			writefunction = h$update)

# Convert to R object
x <- fromJSON(h$value())


