# ===================================================
# RRest Example
#
# To run, run
#   Rscript server_example.R 
# 
# For command line example, in another terminal, run
# curl -X POST http://0.0.0.0:9090 -d '{"fun": "randomNormal", "params" : {"n" : 100}}'
#
# For R example, open another R session and run the contents of "client_example.R"

# The server expects a JSON object of the following form:
# {
#	"fun" : functionName,
#	"params" : {
#		"param1Name" : param1Value,
#		...
#	}
# }

# ==================================================


source('rrest.R')

# Define Sample Functions
randomUniform <- function(p){
  p <- lapply(p, as.numeric)
  runif(p$n)
}

randomNormal <- function(p){
  p <- lapply(p, as.numeric)
  rnorm(p$n)
}

# Add to environment
fun_env <- new.env()
assign('randomUniform', randomUniform, env = fun_env)
assign('randomNormal', randomNormal, env = fun_env)

# Start Server
runServer(host = '0.0.0.0', port = 9090, app = list(call = restServer(fun_env)))

