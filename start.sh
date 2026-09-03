# 1. Сборка общего base-образа (vcpkg manifest: grpc/protobuf/cassandra-cpp-driver/abseil/curl/libxml2
#    + сгенерированные protobuf/grpc заглушки из proto_files/)
docker build -f ./docker/Dockerfile.vcpkg -t base-vcpkg:latest .

# 2. Сборка образов coordinator и worker поверх base-vcpkg
docker build -f ./coordinator/Dockerfile -t distributed_parser-coordinator ./coordinator
docker build -f ./worker/Dockerfile -t distributed_parser-worker ./worker

# 3. Запуск Minikube
minikube start

# 4. Загрузка Docker-образов в Minikube
minikube image load distributed_parser-coordinator:latest
minikube image load distributed_parser-worker:latest

ubectl create configmap cassandra-setup --from-file=setup.cql=.\cassandra\setup.cql

# 5. Применение манифестов
kubectl apply -f ./kubernetes/ --recursive

kubectl port-forward deployment/cassandra-web 8083:8083