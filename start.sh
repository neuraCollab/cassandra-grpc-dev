# 1. Сборка vcpkg-образа (если нужно)
docker build -f ./docker/Dockerfile.vcpkg -t base-vcpkg .
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

# 5. Применение манифестов
kubectl apply -f ./kubernetes/ --recursive