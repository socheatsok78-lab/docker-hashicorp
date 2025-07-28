it:
	docker buildx bake --set=*.platform="" --print
build:
	docker buildx bake --set=*.platform="" --load
