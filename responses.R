
success <- function(resp) {
  paste("HTTP/1.1 200 OK",
        "Content-Type: text/json",
        paste("Content-Length:", nchar(resp, type="bytes")),
        "", resp, sep="\n") 
}

method_not_found <- function() {
  resp = "Method not allowed"
  paste("HTTP/1.1 405 Method Not Allowed",
        "Content-Type: text",
        paste("Content-Length:", nchar(resp, type="bytes")),
        "", resp, sep="\n")
}

throw_error <- function() {
  resp = "Internal server error occured"
  paste("HTTP/1.1 500 Internal Server Error Occured",
        "Content-Type: text",
        paste("Content-Length:", nchar(resp, type="bytes")),
        "", resp, sep="\n")
}
