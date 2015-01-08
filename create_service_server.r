source("service.r")
source("tcp_service.r")

# Define Sample Functions
randomUniform <- function(p) { UseMethod('randomUniform', p) }
randomNormal  <- function(p) { UseMethod('randomNormal', p) }

randomUniform.POST <- function(p){
	p <- lapply(p, as.numeric)
	list(val = runif(p$n))
}
randomUniform.GET <- function(p) {
	list(val = runif(1))
}
randomUniform.default <- function(p) {
	randomUniform.GET()
}

randomNormal.POST <- function(p){
	p <- lapply(p, as.numeric)
	list(val = rnorm(p$n))
}
randomNormal.GET <- function(p) {
	list(val = rnorm(1))
}
randomNormal.default <- function(p) {
	randomNormal.GET()
}


# Add to environment
fun_env <- new.env()
assign('randomUniform', randomUniform, env = fun_env)
assign('randomNormal', randomNormal, env = fun_env)


# Start server
start_service(tcp_service(), call_gen(fun_env), 
              parse_input=parse_html_request, max_num_requests=Inf, parallel=1)

