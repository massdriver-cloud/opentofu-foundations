provider "go" {
    go = file("./lib.go")
}

locals {
    // Note: Function name is all lowercase. No camel casing here.
    record = provider::go::exchangerate({
        currencies = "Canada-Dollar"
    })
    user_data = <<-EOF
                #!/bin/bash
                yum update -y
                amazon-linux-extras install docker -y
                service docker start
                usermod -a -G docker ec2-user
                docker run -d \
                  -e WORDPRESS_DB_HOST=xxxxxxxxxxx \
                  -e WORDPRESS_DB_USER=xxxxxxxxxxxx \
                  -e WORDPRESS_DB_PASSWORD=xxxxxxxxxxxxxxx \
                  -e WORDPRESS_DB_NAME=xxxxxxxxxxxxxxx \
                  -p 80:80 xxxxxxxxxxxx:xxxxxxxxxxxx
              EOF
    exchange_rate_env_string = "  -e CAD_EXCHANGE_RATE=${local.record.exchangeRate} \\"
    split_user_data = split("\n", tostring(local.user_data))
    parsed_user_data = [slice(local.split_user_data, 0, 9), local.exchange_rate_env_string, local.split_user_data[10]]
    joined_user_data = join("\n", flatten(local.parsed_user_data))
}


output "data" {
    value = local.joined_user_data
}