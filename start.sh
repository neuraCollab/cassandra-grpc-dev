# 1. Сборка vcpkg-образа (если нужно)
docker build -f ./docker/Dockerfile.vcpkg -t base-vcpkg .

# сборка grpc и предстартового образа
docker build -f ./docker/Dockerfile.grpc -t grpc .
docker build -f ./docker/Dockerfile.prestart -t prestart .

docker build -f ./coordinator/Dockerfile -t distributed_parser-coordinator .
docker build -f ./worker/Dockerfile -t distributed_parser-worker .
# 2. Генерация gRPC кода
docker run --rm \
  -v $(pwd)/proto_files:/app/proto_files \
  -v $(pwd)/generated:/app/generated \
  grpc-generator

# 3. Запуск Minikube
minikube start

# 4. Загрузка Docker-образов в Minikube
minikube image load distributed_parser-coordinator:latest
minikube image load distributed_parser-worker:latest

ubectl create configmap cassandra-setup --from-file=setup.cql=.\cassandra\setup.cql

# 5. Применение манифестов
kubectl apply -f ./kubernetes/ --recursive

kubectl port-forward deployment/cassandra-web 8083:8083