variable "server_port" {
    description = "The port the server will use for HTTP requests"
    type = number
    default = 8080
    validation {
        condition = var.server_port > 0 && var.server_port < 65536
        error_message = "Invalid port (0-65535)"
    }
}

variable "instance_name" {
    description = "The name of the instance"
    type = string
    default = "server"
}