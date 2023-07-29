locals {
  endpoints = {
    "users" = ["GET"]
    "credit_cards" = ["GET"]
    "items" = ["GET", "POST"]
  }
}

output "some_var" {
  value = merge([
    for path, methods in local.endpoints : {
      for method in methods : "${method}.${path}" => {
        path   = path,
        method = method
      }
    }
  ]...)
}