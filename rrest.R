# =======================
# Server

require(httpuv)
require(RJSONIO)

restServer <- function(fun_env) {
  function(env){
    method <- env[['REQUEST_METHOD']]
    resp   <- '{"null_response" : undefined}'	
    if(method == 'POST') {	
	  postfields <- rawToChar(env[['rook.input']]$read())
	  postfields <- fromJSON(postfields)
	  if(length(postfields) == 2){
	    fun    <- exec_env[[postfields[['fun']]]]
	    if(!is.null(fun)){
	      params <- postfields[['params']]
	      resp   <- toJSON(fun(params))
	    } else {
	      print('unsupported function!')
	    }
	  }
	} else {
	  print('unsupported request!')
	}
		
	list(
	  status = 200L,
	  headers = list('Content-Type' = 'JSON'),
	  body = resp
	)	
  }
}


# ======================
# Server Demo:

# Define Sample Functions...
randomUniform <- function(p){
  p <- lapply(p, as.numeric)
  runif(p$n)
}

randomNormal <- function(p){
  p <- lapply(p, as.numeric)
  rnorm(p$n)
}

fun_env <- new.env()
assign('randomUniform', randomUniform, env = fun_env)
assign('randomNormal', randomNormal, env = fun_env)

runServer(host = '0.0.0.0', port = 9090, app = list(call = restServer(fun_env)))

# The server expects a JSON object of the following form:
# {
	# "fun" : functionName,
	# "params" : {
		# "param1Name" : param1Value,
		# ...
	# }
# }

# ==========================================================================
# R Client Demo:
require(RCurl)
require(RJSONIO)

body <- list(
	fun = 'randomNormal',
	params = list(
		n = 100
	)
)

body <- toJSON(body)
curlPerform(url = 'http://localhost:9090', postfields = body)


# Command line Client Demo:
# curl -X POST http://localhost:9090 -d '{"fun": "randomNormal", "params" : {"n" : 100}}'











