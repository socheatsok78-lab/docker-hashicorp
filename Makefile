target ?= default

it:
	docker buildx bake $(target) --set=*.platform="" --set=*.args.DOCKER_CACHE_KEY=shared --set=*.args.DOCKER_CACHE_PURGE=0 --print
build:
	docker buildx bake $(target) --set=*.platform="" --set=*.args.DOCKER_CACHE_KEY=shared --set=*.args.DOCKER_CACHE_PURGE=0 --load
