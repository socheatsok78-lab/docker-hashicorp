target ?= default

it:
	docker buildx bake $(target) --set=*.platform="" --set=*.args.DOCKER_CACHE_PURGE=1 --print
build:
	docker buildx bake $(target) --set=*.platform="" --set=*.args.DOCKER_CACHE_PURGE=1 --load
