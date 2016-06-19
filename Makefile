all: push

IMAGE_TAG = 1.0
IMAGE_NAME = quay.io/everydayhero/nginx

container:
	docker build -t $(IMAGE_NAME):$(IMAGE_TAG) --pull .

push: container
	docker push $(IMAGE_NAME):$(IMAGE_TAG)

clean:
	docker rmi -f $(IMAGE_NAME):$(IMAGE_TAG) || true
