dir :=
ifneq ($(dir),)
target = $(subst /,_,$(subst .,_,$(dir)))
endif
target ?= default
targets := $(foreach f,$(wildcard **/**/Dockerfile),$(patsubst %/,%,$(dir $(f))))
docker_buildx_build_cmd := docker buildx bake --file docker-bake.hcl $(target)

it:
	@$(MAKE) print | jq -r '.target | keys'
print:
	@$(docker_buildx_build_cmd) --print 2>/dev/null
build: print
	@$(docker_buildx_build_cmd) --load --set="*.platform="
buildx: print
	@$(docker_buildx_build_cmd)
push: print
	@BUILDX_BUILDER=default-builder $(docker_buildx_build_cmd) --push

.PHONY: $(targets)
$(targets):
	$(MAKE) dir=$@ build
