import json

# Terraform Output 파일 로드
with open("../terraform/db_output.json", "r") as file:
    data = json.load(file)

# Bastion Host Public IP 가져오기
bastion_ip = data["bastion_public_ip"]["value"]

# inventory.ini 생성
with open("inventory.ini", "w") as file:
    # PostgreSQL Server 설정
    file.write("[postgresql_server]\n")
    file.write(
        f"{data['pg_server_ip']['value']} "
        f"ansible_user=ubuntu "
        f"ansible_ssh_private_key_file=/Users/mming/Documents/kakao-tech-bootcamp.pem "
        f"ansible_ssh_common_args='-o ProxyCommand=\"ssh -W %h:%p -i /Users/mming/Documents/kakao-tech-bootcamp.pem ubuntu@{bastion_ip}\"'\n"
    )
    
    # Redis Server 설정
    file.write("\n[redis_server]\n")
    file.write(
        f"{data['redis_server_ip']['value']} "
        f"ansible_user=ubuntu "
        f"ansible_ssh_private_key_file=/Users/mming/Documents/kakao-tech-bootcamp.pem "
        f"ansible_ssh_common_args='-o ProxyCommand=\"ssh -W %h:%p -i /Users/mming/Documents/kakao-tech-bootcamp.pem ubuntu@{bastion_ip}\"'\n"
    )
    
    # RabbitMQ Server 설정
    file.write("\n[rabbitmq_server]\n")
    file.write(
        f"{data['rmq_server_ip']['value']} "
        f"ansible_user=ubuntu "
        f"ansible_ssh_private_key_file=/Users/mming/Documents/kakao-tech-bootcamp.pem "
        f"ansible_ssh_common_args='-o ProxyCommand=\"ssh -W %h:%p -i /Users/mming/Documents/kakao-tech-bootcamp.pem ubuntu@{bastion_ip}\"'\n"
    )

print("inventory.ini 생성 완료!")
