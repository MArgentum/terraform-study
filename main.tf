# Указываем провайдер AWS
provider "aws" {
    region = "eu-north-1" # Регион, в котором будет развернута инфраструктура
}

data "aws_vpc" "default_vpc" {
    default = true                                  # Запрос данных о стандартной VPC
}

data "aws_subnets" "default_subnets" {
    filter {
        name = "vpc-id"
        values = [data.aws_vpc.default_vpc.id]
    }
}

# Группа автоматического масштабирования для веб-сервера
resource "aws_autoscaling_group" "web_server_group" {
    launch_template { id = aws_launch_template.server_launch_template.id } # ID шаблона запуска
    
    name = "web-server-group" # Имя группы
    vpc_zone_identifier = data.aws_subnets.default_subnets.ids # Исправлено: убраны квадратные скобки, так как ids уже является списком
    
    target_group_arns = [aws_lb_target_group.web-server-group.arn] # Указываем ARN целевой группы для авто-масштабируемой группы
    health_check_type = "ELB" # Устанавливаем тип проверки состояния на ELB (Elastic Load Balancer)

    min_size = 2 # Минимальное количество экземпляров
    max_size = 10 # Максимальное количество экземпляров
    desired_capacity = 3 # Желаемое количество экземпляров
}

# Шаблон запуска для autoscaling_group
resource "aws_launch_template" "server_launch_template" {
    name                    = "web-server-template"                          # Имя шаблона
    image_id                = "ami-02e2af61198e99faf"                        # ID образа AMI
    instance_type           = "t3.micro"                                     # Тип экземпляра
    vpc_security_group_ids  = [aws_security_group.server_welcome.id]     # ID группы безопасности
    user_data = base64encode(<<-EOF
                #!/bin/bash
                echo "HELLO WORLD" > index.html # Создаем файл index.html с текстом "HELLO WORLD"
                nohup busybox httpd -f -p ${var.server_port} & # Запускаем HTTP сервер на порту, указанном в переменной
                EOF
    )
    lifecycle {
        create_before_destroy = true          # Создавать новый ресурс перед удалением старого
    }
}

# SECURITY-ГРУППА ДЛЯ веб-сервера
resource "aws_security_group" "server_welcome" {
    name = "server-welcome-security-group" # Имя группы безопасности
    vpc_id = data.aws_vpc.default_vpc.id # ID VPC в которой будет создана Security-группа
    ingress {
        from_port = var.server_port # Порт, с которого разрешен доступ
        to_port = var.server_port # Порт, на который разрешен доступ
        protocol = "tcp" # Протокол
        cidr_blocks = ["0.0.0.0/0"] # Разрешаем доступ с любого IP
    }
}
resource "aws_lb" "my_load_balancer" {
    name = "web"
    load_balancer_type = "application"
    security_groups = [aws_security_group.load_balancer.id]
    subnets = data.aws_subnets.default_subnets.ids
}

resource "aws_lb_listener" "http" {
    load_balancer_arn = aws_lb.my_load_balancer.arn
    port = 80
    protocol = "HTTP"
    default_action {
        type = "fixed-response"
        fixed_response {
            content_type = "text/plain"
            message_body = "404: page not found"
            status_code = "404"
        }
    }
}

resource "aws_security_group" "load_balancer" { # Группа безопасности для load balancer
    name = "load-balancer-security-group"
    vpc_id = data.aws_vpc.default_vpc.id
    ingress { # Входящий трафик
        from_port = 80
        to_port = 80
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }
    egress { # Исходящий трафик
        from_port = 0
        to_port = 0
        protocol = "-1" # Все протоколы
        cidr_blocks = ["0.0.0.0/0"]
    }
}

resource "aws_lb_target_group" "web-server-group" {
    name        = "web-server-group"
    port        = var.server_port
    protocol    = "HTTP"
    target_type = "instance"
    vpc_id      = data.aws_vpc.default_vpc.id
    health_check {
        path                = "/"
        protocol            = "HTTP"
        matcher             = "200"
        interval            = 15
        timeout             = 3
        healthy_threshold   = 2
        unhealthy_threshold = 2
    }
}

resource "aws_lb_listener_rule" "web-server-group" {
    listener_arn = aws_lb_listener.http.arn
    priority = 100
    condition {
        path_pattern {
            values = ["*"]
        }
    }
    action {
        type = "forward"
        target_group_arn = aws_lb_target_group.web-server-group.arn
    }
}
