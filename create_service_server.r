source("service.r")

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

call = function(req) {
  resp   <- '{"null_response" : undefined}'
  postfields <- fromJSON(req)
  if(length(postfields) == 2){
    fun <- fun_env[[postfields[['fun']]]]
    if(!is.null(fun)){
      params <- postfields[['params']]
      resp   <- toJSON(fun(params))
    } else { 
      print('unsupported function!')
    }
  }

  ret = list(
    status  = 200L,
    headers = list('Content-Type' = 'JSON'),
    body    = resp
  )
  toJSON(ret)
}


start_service(rrest_socket_connection(), call)
