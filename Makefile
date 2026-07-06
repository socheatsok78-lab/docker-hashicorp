TARGET := $(if $(word 2,$(MAKECMDGOALS)),$(word 2,$(MAKECMDGOALS)),)

it:

.PHONY: consul
consul:
	$(MAKE) -C consul $(TARGET)
.PHONY: openbao
openbao:
	$(MAKE) -C openbao $(TARGET)
.PHONY: vault
vault:
	$(MAKE) -C vault $(TARGET)

# Catch-all rule to prevent Make from throwing errors 
# if the second value is treated as a literal target
%:
	@:
