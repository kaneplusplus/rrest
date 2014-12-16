source("service.r")

# Define Sample Functions
randomUniform <- function(p) { UseMethod('randomUniform', p) }
randomNormal  <- function(p) { UseMethod('randomNormal', p) }

randomUniform.POST <- function(p){
	p <- lapply(p, as.numeric)
	runif(p$n)
}
randomUniform.GET <- function(p) {
	runif(1)
}
randomUniform.default <- function(p) {
	randomUniform.GET()
}

randomNormal.POST <- function(p){
  p <- lapply(p, as.numeric)
  rnorm(p$n)
}
randomNormal.GET <- function(p) {
	rnorm(1)
}
randomNormal.default <- function(p) {
	randomNormal.GET()
}


# Add to environment
fun_env <- new.env()
assign('randomUniform', randomUniform, env = fun_env)
assign('randomNormal', randomNormal, env = fun_env)


# Start server
start_service(rrest_socket_connection(), fun_env)
